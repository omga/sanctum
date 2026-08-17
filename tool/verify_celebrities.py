#!/usr/bin/env python3
"""Check every bundled celebrity birth date against Wikidata.

    python3 tool/verify_celebrities.py [--titles tool/celebrity_titles.json]

The birth date is the only factual claim this app makes about a real
person, and a wrong one puts the wrong sign beside their name in
something a user posts publicly. The catalogue was originally written
from memory; this is what replaced that.

It resolves each person through their English Wikipedia article rather
than through Wikidata's search endpoint, because search is fuzzy and
happily returns a given-name entity for a mononym — "Rihanna" matched
"female given name" and "Dua Lipa" matched the album. Titles that are
ambiguous are pinned in the sidecar JSON.

Exit code is non-zero if anything disagrees, so it can gate a release.
"""
from __future__ import annotations

import argparse
import json
import pathlib
import subprocess
import sys
import time
import urllib.parse
from datetime import date

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOGUE = ROOT / 'assets/content/celebrities.json'
TITLES = ROOT / 'tool/celebrity_titles.json'
API = 'https://www.wikidata.org/w/api.php'
UA = 'SanctumCelebrityCheck/1.0 (https://github.com/; dev verification)'

# Day precision. Wikidata also stores month-, year- and decade-precision
# dates, and a year-precision value renders as 1 January — which would
# sail through a naive check and show the wrong sign.
DAY_PRECISION = 11


def fetch(url: str, tries: int = 6) -> dict:
    """GET *url* as JSON, backing off on the API's rate limiter."""
    for attempt in range(tries):
        done = subprocess.run(
            ['curl', '-s', '--max-time', '30', '-H', f'User-Agent: {UA}', url],
            capture_output=True, text=True,
        )
        if done.returncode == 0 and done.stdout.strip().startswith('{'):
            try:
                return json.loads(done.stdout)
            except json.JSONDecodeError:
                pass
        time.sleep(2.0 * (attempt + 1))
    return {}


def birth_date(entity: dict) -> tuple[str | None, int | None]:
    """The P569 value, preferring statements ranked preferred."""
    claims = entity.get('claims', {}).get('P569', [])
    ranked = [c for c in claims if c.get('rank') == 'preferred'] or claims
    for claim in ranked:
        try:
            value = claim['mainsnak']['datavalue']['value']
            return value['time'][1:11], value['precision']
        except (KeyError, TypeError):
            continue
    return None, None


PROPS = 'claims|descriptions|sitelinks'


def _collect(data: dict, found: dict[str, dict], key_by_qid: bool) -> None:
    for qid, entity in data.get('entities', {}).items():
        if qid.startswith('-') or 'missing' in entity:
            continue
        entity = entity | {'_qid': qid}
        if key_by_qid:
            found[qid] = entity
            continue
        title = entity.get('sitelinks', {}).get('enwiki', {}).get('title')
        if title:
            found[title] = entity


def resolve(keys: list[str]) -> dict[str, dict]:
    """Map each key -> Wikidata entity, 25 at a time.

    A key is either an English Wikipedia article title or a `Q…` id.
    Ids are worth preferring for anyone whose article title is contested:
    "Lisa (Thai rapper)" resolved fine one week and 404'd the next when
    the article moved to "Lisa (rapper)", and a verification tool that
    breaks when an editor renames a page is one nobody keeps running.
    """
    qids = [k for k in keys if k.startswith('Q') and k[1:].isdigit()]
    titles = [k for k in keys if k not in set(qids)]
    found: dict[str, dict] = {}

    for start in range(0, len(titles), 25):
        chunk = urllib.parse.quote('|'.join(titles[start:start + 25]))
        _collect(fetch(f'{API}?action=wbgetentities&sites=enwiki&titles={chunk}'
                       f'&props={PROPS}&sitefilter=enwiki&languages=en'
                       '&format=json'), found, key_by_qid=False)
        time.sleep(0.8)

    for start in range(0, len(qids), 25):
        chunk = '|'.join(qids[start:start + 25])
        _collect(fetch(f'{API}?action=wbgetentities&ids={chunk}'
                       f'&props={PROPS}&sitefilter=enwiki&languages=en'
                       '&format=json'), found, key_by_qid=True)
        time.sleep(0.8)

    return found


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--titles', type=pathlib.Path, default=TITLES)
    parser.add_argument('--quiet', action='store_true')
    args = parser.parse_args()

    people = json.loads(CATALOGUE.read_text())['celebrities']
    overrides = json.loads(args.titles.read_text()) if args.titles.exists() else {}
    wanted = {p['id']: overrides.get(p['id'], p['name']) for p in people}

    entities = resolve(sorted(set(wanted.values())))
    today = date.today()
    problems: list[str] = []

    for person in people:
        title = wanted[person['id']]
        entity = entities.get(title)
        if entity is None:
            problems.append(f"{person['id']}: {title!r} did not resolve — "
                            f'pin a Q-id in {args.titles.name}')
            continue

        found, precision = birth_date(entity)
        if found is None:
            problems.append(f"{person['id']}: {entity['_qid']} has no P569")
            continue
        if precision != DAY_PRECISION:
            problems.append(f"{person['id']}: {entity['_qid']} date is "
                            f'precision {precision}, not a known day')
            continue
        if found != person['birthDate']:
            problems.append(f"{person['id']}: catalogue says "
                            f"{person['birthDate']}, Wikidata says {found} "
                            f"({entity['_qid']})")
            continue

        year, month, day = (int(part) for part in found.split('-'))
        age = today.year - year - ((today.month, today.day) < (month, day))
        if age < 18:
            problems.append(f"{person['id']}: under 18 (born {found})")
            continue

        if not args.quiet:
            print(f"  ok  {person['id']:<24} {found}  {entity['_qid']}")

    print(f'\n{len(people)} checked, {len(problems)} problem(s)')
    for line in problems:
        print(f'  !!  {line}')
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())

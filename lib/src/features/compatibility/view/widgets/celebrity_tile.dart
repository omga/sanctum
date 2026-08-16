import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/celebrity.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/sign_avatar.dart';

/// One person in the celebrity picker.
class CelebrityTile extends StatelessWidget {
  /// Creates a tile.
  const CelebrityTile({
    required this.celebrity,
    required this.onTap,
    this.matched = false,
    super.key,
  });

  /// Who it is.
  final Celebrity celebrity;

  /// Tap handler.
  final VoidCallback onTap;

  /// Whether the user has already revealed this pairing.
  final bool matched;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return Semantics(
      button: true,
      label: celebrity.name,
      child: GestureDetector(
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          onTap();
        },
        child: AnimatedContainer(
          duration: SanctumMotion.quick,
          padding: const EdgeInsets.all(SanctumSpacing.md),
          decoration: BoxDecoration(
            borderRadius: SanctumRadii.lgAll,
            color: colors.glassFill,
            border: Border.all(
              color: matched ? colors.gold : colors.glassBorder,
            ),
          ),
          child: Row(
            children: [
              SignAvatar(sign: celebrity.sign, size: 48),
              const SizedBox(width: SanctumSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      celebrity.name,
                      style: type.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${celebrity.sign.displayName} · '
                      '${celebrity.knownFor}',
                      style: type.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                matched ? Icons.check_circle : Icons.chevron_right,
                size: 20,
                color: matched ? colors.gold : colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

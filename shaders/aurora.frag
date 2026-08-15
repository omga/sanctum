#version 460 core
#include <flutter/runtime_effect.glsl>

// Sanctum's signature background: three slow-drifting aurora blooms over
// a vertical night gradient.
//
// Why a shader instead of stacked Containers with gradients? Because this
// runs entirely on the GPU as a single draw call. The equivalent Flutter
// widget tree would be several blurred, animated, overlapping layers —
// each one a separate render target the raster thread has to composite
// every frame. On mid-range Android that is the difference between a
// smooth background and a stuttering one.

precision highp float;

// Uniform order here IS the index order used from Dart. Each float
// component consumes one index: uSize takes 0-1, uTime 2, uColorA 3-5,
// and so on. Reordering these without updating AuroraBackground will
// silently produce nonsense colours rather than an error.
uniform vec2 uSize;
uniform float uTime;
uniform vec3 uColorA;
uniform vec3 uColorB;
uniform vec3 uColorC;
uniform vec3 uBgTop;
uniform vec3 uBgBottom;
uniform float uIntensity;

out vec4 fragColor;

// Smooth, never-quite-zero falloff. A Gaussian reads far softer than
// smoothstep, which leaves a visible edge where the blob ends.
float bloom(vec2 p, vec2 centre, float radius) {
  float d = length(p - centre);
  return exp(-(d * d) / (2.0 * radius * radius));
}

// Cheap hash for dithering.
float hash21(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;

  // Correct for aspect so blooms stay circular instead of stretching
  // into ovals on tall phone screens.
  float aspect = uSize.x / uSize.y;
  vec2 p = vec2(uv.x * aspect, uv.y);

  float t = uTime;

  // Base night gradient, deepest at the top.
  vec3 col = mix(uBgTop, uBgBottom, smoothstep(0.0, 1.0, uv.y));

  // Three centres on slow, mutually prime Lissajous paths. Prime-ish
  // frequency ratios stop the motion from ever visibly repeating.
  //
  // Radii are deliberately SMALL relative to the screen. Because x is
  // aspect-corrected, p spans only ~0.46 across on a tall phone while y
  // spans 1.0 — so a radius of 0.4 here is not "a large blob", it is
  // "the entire screen", and three of those summing additively blows the
  // night sky out to a flat lavender wash that destroys text contrast.
  // Keep these under ~0.25.
  //
  // The centres also sit high and low, leaving the middle band — where
  // body copy lives — comparatively dark.
  vec2 c1 = vec2(aspect * (0.24 + 0.16 * sin(t * 0.110)),
                 0.12 + 0.07 * cos(t * 0.087));
  vec2 c2 = vec2(aspect * (0.88 + 0.14 * cos(t * 0.071)),
                 0.40 + 0.10 * sin(t * 0.129));
  vec2 c3 = vec2(aspect * (0.42 + 0.18 * sin(t * 0.053)),
                 0.94 + 0.08 * cos(t * 0.101));

  // Additive light. Aurora is emitted light, not pigment, so blooms add
  // rather than blend — overlaps get brighter, which is what sells it.
  col += uColorA * bloom(p, c1, 0.22) * 0.42 * uIntensity;
  col += uColorB * bloom(p, c2, 0.18) * 0.34 * uIntensity;
  col += uColorC * bloom(p, c3, 0.16) * 0.26 * uIntensity;

  // Vignette, to keep attention centred.
  float vig = 1.0 - 0.38 * length(uv - vec2(0.5)) ;
  col *= clamp(vig, 0.0, 1.0);

  // Dither. Smooth dark gradients band badly on 8-bit displays; a sub-LSB
  // of noise breaks the contours up and costs nothing.
  col += (hash21(uv * uSize) - 0.5) * (1.5 / 255.0);

  fragColor = vec4(col, 1.0);
}

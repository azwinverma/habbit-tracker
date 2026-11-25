import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Brand page background: a soft tonal wash from the page's tint (Mint by
/// default, or a category colour) into the app background, two faint glows
/// and, optionally, a quiet Himalayan ridge line at the top.
///
/// Brand rule: the wash stays behind content only. Cards, buttons and text
/// keep their flat brand colours, so contrast is unchanged.
///
/// Opaque, so it is safe under page transitions. Put a transparent
/// [Scaffold] inside it:
/// `BrandBackdrop(child: Scaffold(backgroundColor: Colors.transparent, ...))`.
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({super.key, required this.child, this.tint, this.glow, this.ridge = false});
  final Widget child;

  /// Top wash colour (defaults to the brand Mint / dark teal container).
  final Color? tint;

  /// Accent for the soft glows (defaults to the primary colour).
  final Color? glow;

  /// Draw the mountain ridge line (Today, onboarding, splash).
  final bool ridge;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final dark = s.brightness == Brightness.dark;
    final bg = dark ? BrandColors.backgroundDark : BrandColors.backgroundLight;
    final top = tint ?? (dark ? const Color(0xFF123B38) : BrandColors.mint);
    return CustomPaint(
      painter: _BackdropPainter(
        background: bg,
        top: top,
        glow: glow ?? s.primary,
        second: dark ? BrandColors.lavender : BrandColors.coral,
        ridge: ridge ? (dark ? BrandColors.mint : BrandColors.deepTeal) : null,
        dark: dark,
      ),
      child: child,
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({
    required this.background,
    required this.top,
    required this.glow,
    required this.second,
    required this.ridge,
    required this.dark,
  });
  final Color background, top, glow, second;
  final Color? ridge;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = background);

    // Tonal wash: tint at the top, fading into the background by ~45%.
    final washH = math.min(size.height * 0.45, 520.0);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, washH),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top.withValues(alpha: dark ? 0.75 : 0.95), top.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, washH)),
    );

    // Soft glows (very low alpha): primary top-right, warm/cool lower-left.
    void glowAt(Offset c, double r, Color color, double a) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: a), color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    glowAt(Offset(size.width * 0.95, size.height * 0.04), size.width * 0.7, glow, dark ? 0.16 : 0.12);
    glowAt(Offset(size.width * 0.02, size.height * 0.62), size.width * 0.75, second, dark ? 0.07 : 0.08);

    final r = ridge;
    if (r != null) _ridge(canvas, size, r);
  }

  void _ridge(Canvas canvas, Size size, Color color) => paintRidge(
    canvas,
    size.width,
    math.min(size.height * 0.30, 300.0),
    color,
    dark ? 0.07 : 0.05,
    dark ? 0.09 : 0.07,
  );

  @override
  bool shouldRepaint(covariant _BackdropPainter o) =>
      o.background != background || o.top != top || o.glow != glow || o.ridge != ridge || o.second != second;
}

/// Two layered mountain silhouettes (Himalaya nod) whose foot is at
/// [base]; [backA]/[frontA] are the peak opacities (kept very low).
void paintRidge(Canvas canvas, double w, double base, Color color, double backA, double frontA, {double height = 1}) {
  final h = base * height;
  Path range(List<Offset> pts) {
    final p = Path()..moveTo(0, base);
    for (final o in pts) {
      p.lineTo(o.dx * w, base - (1 - o.dy) * h);
    }
    p
      ..lineTo(w, base)
      ..close();
    return p;
  }

  final back = range(const [
    Offset(0, 0.70),
    Offset(0.14, 0.52),
    Offset(0.24, 0.62),
    Offset(0.38, 0.34),
    Offset(0.47, 0.46),
    Offset(0.58, 0.28),
    Offset(0.70, 0.50),
    Offset(0.82, 0.40),
    Offset(1, 0.62),
  ]);
  final front = range(const [
    Offset(0, 0.86),
    Offset(0.18, 0.70),
    Offset(0.30, 0.80),
    Offset(0.46, 0.60),
    Offset(0.60, 0.76),
    Offset(0.76, 0.64),
    Offset(0.90, 0.78),
    Offset(1, 0.72),
  ]);
  Shader fade(double a) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [color.withValues(alpha: a), color.withValues(alpha: 0)],
  ).createShader(Rect.fromLTWH(0, base - h * 0.75, w, h * 0.75));
  canvas.drawPath(back, Paint()..shader = fade(backA));
  canvas.drawPath(front, Paint()..shader = fade(frontA));
}

/// Splash background: Deep Teal deepening toward the bottom, a soft Mint
/// glow behind the mark and a faint ridge line.
class SplashBackdrop extends StatelessWidget {
  const SplashBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _SplashPainter(), child: child);
}

class _SplashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [BrandColors.deepTeal, Color(0xFF0F504D)],
        ).createShader(rect),
    );
    final c = Offset(size.width / 2, size.height * 0.45);
    final r = size.width * 0.8;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [BrandColors.mint.withValues(alpha: 0.16), BrandColors.mint.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    paintRidge(canvas, size.width, size.height * 0.86, BrandColors.mint, 0.08, 0.11, height: 0.35);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

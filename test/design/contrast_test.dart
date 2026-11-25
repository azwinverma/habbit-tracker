import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/app/theme.dart';

/// WCAG 2.x contrast ratio.
double contrast(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final l1 = lum(a), l2 = lum(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  for (final b in Brightness.values) {
    group('${b.name} theme', () {
      final t = buildTheme(b);
      final s = t.colorScheme;
      final dm = t.extension<DmColors>()!;
      final card = t.cardTheme.color!;

      // Body text needs 4.5:1 (AA).
      final text = <String, (Color, Color)>{
        'onSurface / background': (s.onSurface, s.surface),
        'onSurface / card': (s.onSurface, card),
        'muted text / background': (s.onSurfaceVariant, s.surface),
        'muted text / card': (s.onSurfaceVariant, card),
        'primary (text buttons) / card': (s.primary, card),
        'primary (text buttons) / background': (s.primary, s.surface),
        'onPrimary / primary (filled buttons)': (s.onPrimary, s.primary),
        'onPrimaryContainer / primaryContainer (hero)': (s.onPrimaryContainer, s.primaryContainer),
        'onPrimaryContainer / hero gradient end': (s.onPrimaryContainer, heroGradientEnd(s)),
        // Headings and labels sit directly on the backdrop wash (worst case:
        // the full-strength tint at the very top).
        'onSurface / brand wash': (s.onSurface, b == Brightness.dark ? const Color(0xFF123B38) : BrandColors.mint),
        'muted text / brand wash': (s.onSurfaceVariant, b == Brightness.dark ? const Color(0xFF123B38) : BrandColors.mint),
        for (final (n, p) in [('water', dm.water), ('medicine', dm.medicine), ('mind', dm.mind), ('reading', dm.reading), ('movement', dm.movement)])
          'muted text / $n wash': (s.onSurfaceVariant, p.container),
        'onTertiaryContainer / tertiaryContainer (quote)': (s.onTertiaryContainer, s.tertiaryContainer),
        'onSecondaryContainer / secondaryContainer (chips)': (s.onSecondaryContainer, s.secondaryContainer),
        'error / background': (s.error, s.surface),
        'success / card': (dm.success, card),
        'warning / card': (dm.warning, card),
        for (final (n, p) in [
          ('medicine', dm.medicine), ('water', dm.water), ('mind', dm.mind),
          ('reading', dm.reading), ('movement', dm.movement), ('habit', dm.habit),
        ])
          '$n onContainer / container': (p.onContainer, p.container),
      };
      for (final e in text.entries) {
        test('AA text: ${e.key}', () {
          final r = contrast(e.value.$1, e.value.$2);
          expect(r, greaterThanOrEqualTo(4.5), reason: '${e.key} = ${r.toStringAsFixed(2)}:1');
        });
      }

      // Icons, rings and other meaningful graphics need 3:1 (WCAG 1.4.11).
      final graphics = <String, (Color, Color)>{
        for (final (n, p) in [
          ('medicine', dm.medicine), ('water', dm.water), ('mind', dm.mind),
          ('reading', dm.reading), ('movement', dm.movement), ('habit', dm.habit),
        ]) ...{
          '$n accent / container (badge icon)': (p.accent, p.container),
          '$n accent / card (ring)': (p.accent, card),
        },
        'outline (unchecked circle) / card': (s.outline, card),
        'primary ring / primaryContainer': (s.primary, s.primaryContainer),
      };
      for (final e in graphics.entries) {
        test('3:1 graphic: ${e.key}', () {
          final r = contrast(e.value.$1, e.value.$2);
          expect(r, greaterThanOrEqualTo(3.0), reason: '${e.key} = ${r.toStringAsFixed(2)}:1');
        });
      }
    });
  }
}

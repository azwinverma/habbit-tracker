import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/habit.dart';
import 'motion.dart';

/// Shared DailyMantra UI components. Screens compose these instead of
/// styling widgets ad hoc, so everything reads as one product.

// ------------------------------------------------------------------ category

CategoryPalette paletteFor(HabitCategory c, DmColors dm) => switch (c) {
  HabitCategory.medicine => dm.medicine,
  HabitCategory.water => dm.water,
  HabitCategory.meditation => dm.mind,
  HabitCategory.reading => dm.reading,
  HabitCategory.exercise => dm.movement,
  HabitCategory.generic => dm.habit,
};

IconData iconFor(HabitCategory c) => switch (c) {
  HabitCategory.medicine => Icons.medication_rounded,
  HabitCategory.water => Icons.water_drop_rounded,
  HabitCategory.meditation => Icons.self_improvement_rounded,
  HabitCategory.reading => Icons.auto_stories_rounded,
  HabitCategory.exercise => Icons.directions_run_rounded,
  HabitCategory.generic => Icons.task_alt_rounded,
};

/// Rounded-square icon on a soft category tint.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.icon, required this.palette, this.size = 44});
  final IconData icon;
  final CategoryPalette palette;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: palette.container, borderRadius: BorderRadius.circular(size * 0.32)),
    child: Icon(icon, color: palette.accent, size: size * 0.52),
  );
}

// ------------------------------------------------------------------ surfaces

/// The standard card: 24-radius, hairline border, optional tap + tint.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding = const EdgeInsets.all(Space.lg),
    this.semanticLabel,
  });
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final card = Pressable(
      enabled: onTap != null,
      child: Card(
        color: color,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
    return semanticLabel == null
        ? card
        : Semantics(label: semanticLabel, button: onTap != null, container: true, child: card);
  }
}

/// Section title with an optional trailing text action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.sm, Space.sm),
    child: Row(
      children: [
        Expanded(child: Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleLarge))),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

// ------------------------------------------------------------------ progress

/// Animated circular progress (0..1). Animation is skipped when the OS asks
/// for reduced motion.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 64,
    this.stroke = 8,
    this.color,
    this.trackColor,
    this.child,
    this.semanticsLabel,
    this.semanticsValue,
  });
  final double value;
  final double size;
  final double stroke;
  final Color? color;
  final Color? trackColor;
  final Widget? child;
  final String? semanticsLabel;
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticsLabel,
      value: semanticsValue,
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: v),
          duration: Motion.of(context, Motion.medium),
          curve: Motion.curve,
          builder:
              (context, a, child) => CustomPaint(
                painter: _RingPainter(a, stroke, color ?? s.primary, trackColor ?? s.surfaceContainerHighest),
                child: Center(child: child),
              ),
          child: child,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.stroke, this.color, this.track);
  final double value, stroke;
  final Color color, track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final base =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, base..color = track);
    if (value > 0) {
      canvas.drawArc(r, -math.pi / 2, math.pi * 2 * value, false, base..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.value != value || o.color != color || o.track != track || o.stroke != stroke;
}

// ------------------------------------------------------------------ status

/// Small rounded status pill (icon + label).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.icon, this.color, this.background});
  final String label;
  final IconData? icon;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final fg = color ?? s.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? s.secondaryContainer,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ states

/// Friendly empty state: icon on a soft circle, title, body, optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.body, this.actionLabel, this.onAction});
  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
            child: Icon(icon, size: 40, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: Space.lg),
          Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          if (body != null) ...[
            const SizedBox(height: Space.sm),
            Text(
              body!,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: Space.lg),
            FilledButton.icon(onPressed: onAction, icon: const Icon(Icons.add), label: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Loading placeholder that gently pulses (static with reduced motion).
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height = 16, this.width, this.radius = Radii.sm});
  final double height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween(begin: 0.55, end: 1.0).animate(_c),
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: s.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

/// Round check button for one-tap completion, with a soft scale "pop".
class CompleteButton extends StatelessWidget {
  const CompleteButton({super.key, required this.done, required this.onTap, required this.semanticLabel, this.color});
  final bool done;
  final VoidCallback? onTap;
  final String semanticLabel;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final c = color ?? s.primary;
    return Semantics(
      button: true,
      checked: done,
      label: semanticLabel,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: AnimatedScale(
              scale: done ? 1.0 : 0.92,
              duration: Motion.of(context, Motion.short),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: Motion.of(context, Motion.short),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? c : Colors.transparent,
                  border: Border.all(color: done ? c : s.outline, width: 2),
                ),
                child: done ? Icon(Icons.check_rounded, size: 20, color: s.surface) : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

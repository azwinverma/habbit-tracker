import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../app/theme.dart';

/// iOS-style scrolling everywhere: elastic overscroll ("bounce") instead of
/// the Android glow, and lists always scrollable so pull-to-refresh and the
/// bounce work even when content is short.
class DmScrollBehavior extends MaterialScrollBehavior {
  const DmScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;

  @override
  Set<PointerDeviceKind> get dragDevices => {...super.dragDevices, PointerDeviceKind.mouse, PointerDeviceKind.trackpad};
}

/// Fades and slides a child up into place once, staggered by [index] so a
/// list of cards cascades in. No timers (safe in tests); instant when the
/// OS "remove animations" setting is on.
class Entrance extends StatefulWidget {
  const Entrance({super.key, required this.child, this.index = 0, this.offset = 24});
  final Widget child;
  final int index;

  /// Start offset in logical pixels below the final position.
  final double offset;

  /// Wraps each child with a staggered [Entrance].
  static List<Widget> list(List<Widget> children, {int start = 0}) => [
    for (var i = 0; i < children.length; i++) Entrance(index: start + i, child: children[i]),
  ];

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  static const _step = 55; // ms between items
  static const _maxDelay = 440; // later items don't wait longer
  static const _run = 520;

  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    final delay = (widget.index * _step).clamp(0, _maxDelay);
    final total = delay + _run;
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: total));
    _t = CurvedAnimation(parent: _c, curve: Interval(delay / total, 1, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status == AnimationStatus.dismissed) {
      if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (_, child) {
        final v = _t.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * widget.offset), child: child),
        );
      },
    );
  }
}

/// Gentle "press in" scale for tappable surfaces (iOS-like feedback on top
/// of the ink ripple).
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.enabled = true, this.scale = 0.97});
  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.enabled && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Motion.of(context, const Duration(milliseconds: 140)),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Soft fade-through when switching bottom-navigation tabs. The child is
/// never rebuilt from scratch (tab state is kept); only the animation
/// restarts when [index] changes.
class TabFadeThrough extends StatefulWidget {
  const TabFadeThrough({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<TabFadeThrough> createState() => _TabFadeThroughState();
}

class _TabFadeThroughState extends State<TabFadeThrough> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void didUpdateWidget(covariant TabFadeThrough old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && MediaQuery.maybeDisableAnimationsOf(context) != true) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (_, child) {
        final v = _t.value;
        return Opacity(
          opacity: 0.35 + 0.65 * v,
          child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child),
        );
      },
    );
  }
}

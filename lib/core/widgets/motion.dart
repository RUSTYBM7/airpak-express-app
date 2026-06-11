import 'package:flutter/material.dart';

/// Tween / curve library for the 2050 motion language.
class MotionCurves {
  /// Smooth deceleration — used for hero transitions, large title resize.
  static const Curve hero = Cubic(0.16, 1, 0.3, 1);

  /// Spring-like overshoot — used for chip selection, press feedback.
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1);

  /// Ease-in-out for ambient effects (pulse, breathe, idle).
  static const Curve ambient = Cubic(0.4, 0, 0.6, 1);
}

class MotionDurations {
  static const Duration tap = Duration(milliseconds: 120);
  static const Duration short = Duration(milliseconds: 240);
  static const Duration medium = Duration(milliseconds: 420);
  static const Duration long = Duration(milliseconds: 700);
  static const Duration hero = Duration(milliseconds: 900);
}

/// Animated counter that tweens between values. Used for KPIs.
class AnimatedCounter extends StatelessWidget {
  final double value;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final int decimals;
  final Duration duration;
  const AnimatedCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.decimals = 0,
    this.duration = MotionDurations.medium,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: MotionCurves.hero,
      builder: (_, v, __) {
        final s = v.toStringAsFixed(decimals);
        return Text('$prefix$s$suffix', style: style);
      },
    );
  }
}

/// Shimmer placeholder for loading state. iOS-style subtle.
class Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  const Shimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? Theme.of(context).colorScheme.surfaceContainerHighest;
    final hl = widget.highlightColor ?? Theme.of(context).colorScheme.surface;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: const Alignment(-1.0, 0),
              end: const Alignment(1.0, 0),
              colors: [base, hl, base],
              stops: [
                (_c.value - 0.3).clamp(0.0, 1.0),
                _c.value.clamp(0.0, 1.0),
                (_c.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Pulsing dot used for "live" / "tracking" / "online" indicators.
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulseDot({super.key, this.color = const Color(0xFF10B981), this.size = 8});
  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return SizedBox(
          width: widget.size * 3,
          height: widget.size * 3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size * 3 * _c.value,
                height: widget.size * 3 * _c.value,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.4 * (1 - _c.value)),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Apple Intelligence-style rotating glow gradient. Used for AI avatar.
class AppleIntelligenceGlow extends StatefulWidget {
  final double size;
  final Widget child;
  final bool active;
  const AppleIntelligenceGlow({
    super.key,
    required this.size,
    required this.child,
    this.active = true,
  });
  @override
  State<AppleIntelligenceGlow> createState() => _AppleIntelligenceGlowState();
}

class _AppleIntelligenceGlowState extends State<AppleIntelligenceGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 4))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Container(
          width: widget.size,
          height: widget.size,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment(1 + _c.value, 0),
              end: Alignment(-1 - _c.value, 0),
              colors: widget.active
                  ? const [
                      Color(0xFFFD79A8),
                      Color(0xFFA29BFE),
                      Color(0xFF6C5CE7),
                      Color(0xFF0984E3),
                      Color(0xFFFD79A8),
                    ]
                  : const [
                      Color(0xFF6B6B70),
                      Color(0xFF3A3A3C),
                    ],
            ),
            boxShadow: widget.active
                ? [
                    BoxShadow(
                      color: const Color(0xFFA29BFE)
                          .withValues(alpha: 0.45 + 0.3 * _c.value),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: ClipOval(child: widget.child),
            ),
          ),
        );
      },
    );
  }
}

/// Page route with iOS-style slide+fade transition.
class IosPageRoute<T> extends PageRouteBuilder<T> {
  IosPageRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: MotionDurations.medium,
          reverseTransitionDuration: MotionDurations.short,
          pageBuilder: (ctx, anim, _) => builder(ctx),
          transitionsBuilder: (ctx, anim, sec, child) {
            final tween = Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            );
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: anim,
                curve: MotionCurves.hero,
              ),
              child: SlideTransition(
                position: tween.animate(CurvedAnimation(
                    parent: anim, curve: MotionCurves.hero)),
                child: child,
              ),
            );
          },
        );
}

/// Animated linear progress bar that fills from 0→value.
class AnimatedProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final Color trackColor;
  final double height;
  final Duration duration;
  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.trackColor = const Color(0xFFFEE2E2),
    this.height = 6,
    this.duration = MotionDurations.long,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: duration,
      curve: MotionCurves.hero,
      builder: (_, v, __) {
        return LayoutBuilder(
          builder: (_, c) {
            return Stack(
              children: [
                Container(
                  width: c.maxWidth,
                  height: height,
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
                Container(
                  width: c.maxWidth * v,
                  height: height,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Scale-tap wrapper: gives a press feedback animation.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
    this.duration = MotionDurations.tap,
  });
  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scaleDown : 1.0,
        duration: widget.duration,
        curve: MotionCurves.spring,
        child: widget.child,
      ),
    );
  }
}

/// Float-in entrance for list items, staggered via [index].
class StaggeredFadeIn extends StatelessWidget {
  final int index;
  final Duration delayStep;
  final Duration duration;
  final Widget child;
  final double slideY;
  const StaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.delayStep = const Duration(milliseconds: 60),
    this.duration = MotionDurations.medium,
    this.slideY = 12,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + (delayStep * index),
      curve: MotionCurves.hero,
      builder: (_, v, child) {
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, slideY * (1 - v)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Hero card with subtle parallax: text follows scroll slightly faster.
class ParallaxHero extends StatelessWidget {
  final ScrollableState scrollable;
  final double heroHeight;
  final Widget background;
  final Widget foreground;
  final double parallaxFactor;
  const ParallaxHero({
    super.key,
    required this.scrollable,
    required this.heroHeight,
    required this.background,
    required this.foreground,
    this.parallaxFactor = 0.25,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollable.position,
      builder: (context, _) {
        final offset = scrollable.position.pixels;
        final translate = (offset * parallaxFactor).clamp(-40.0, 40.0);
        return SizedBox(
          height: heroHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: Offset(0, -translate * 0.4),
                child: background,
              ),
              Transform.translate(
                offset: Offset(0, translate * 0.6),
                child: foreground,
              ),
            ],
          ),
        );
      },
    );
  }
}

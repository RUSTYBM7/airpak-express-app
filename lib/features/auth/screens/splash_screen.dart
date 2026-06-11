import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system.dart';
import '../../../app/router.dart';
import '../../../core/widgets/airpak_brand.dart';
import '../../auth/providers/auth_controller.dart';

/// Animated splash screen. Boots the auth state, displays the brand
/// mark with a scale + rotate-in animation, then routes to the right
/// destination.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _markCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _textCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _outCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  late final Animation<double> _markScale = CurvedAnimation(
    parent: _markCtl,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _markRotate = Tween<double>(
    begin: -0.18,
    end: 0,
  ).animate(CurvedAnimation(parent: _markCtl, curve: Curves.easeOutCubic));
  late final Animation<double> _markGlow = Tween<double>(
    begin: 0,
    end: 1,
  ).animate(CurvedAnimation(parent: _markCtl, curve: Curves.easeInOut));
  late final Animation<double> _textFade = CurvedAnimation(
    parent: _textCtl,
    curve: Curves.easeOut,
  );
  late final Animation<double> _out = CurvedAnimation(
    parent: _outCtl,
    curve: Curves.easeInCubic,
  );

  Timer? _nav;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    _markCtl.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _textCtl.forward();
    });
    // Wait at least 1.4s for the animation, and at most for auth bootstrap.
    final minHold = Future.delayed(const Duration(milliseconds: 1400));
    await minHold;
    // If still initializing, wait for it.
    while (mounted && ref.read(authControllerProvider).initializing) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;
    await _outCtl.forward();
    _route();
  }

  void _route() {
    final auth = ref.read(authControllerProvider);
    if (!mounted) return;
    if (auth.authenticated) {
      context.go(auth.role.name == 'admin'
          ? AppRoutes.adminPortal
          : AppRoutes.portalDashboard);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _markCtl.dispose();
    _textCtl.dispose();
    _outCtl.dispose();
    _nav?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      body: AnimatedBuilder(
        animation: Listenable.merge([_markCtl, _textCtl, _outCtl]),
        builder: (_, __) {
          final fadeOut = (1 - _out.value).clamp(0.0, 1.0);
          return Opacity(
            opacity: fadeOut,
            child: Stack(
              children: [
                // Brand backdrop
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFEF2F2),
                        Color(0xFFFFFFFF),
                      ],
                    ),
                  ),
                ),
                // Animated glow ring
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 320 * _markGlow.value,
                      height: 320 * _markGlow.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.brand
                                .withValues(alpha: 0.18 * _markGlow.value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Center mark + wordmark
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: _markScale.value,
                        child: Transform.rotate(
                          angle: _markRotate.value * math.pi,
                          child: AirpakMark(size: 110),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Opacity(
                        opacity: _textFade.value,
                        child: AirpakWordmark(
                            size: 42, showUnderline: true),
                      ),
                      const SizedBox(height: 10),
                      Opacity(
                        opacity: _textFade.value,
                        child: Text(
                          'E X P R E S S',
                          style: TextStyle(
                            color: AppColors.brand,
                            fontSize: 12,
                            letterSpacing: 6,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: _textFade.value,
                        child: Text(
                          'Global logistics, real-time tracking',
                          style: TextStyle(
                            color: context.textMutedColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom — status line + dots loader
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 48,
                  child: Opacity(
                    opacity: _textFade.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _ThreeDotsLoader(),
                        const SizedBox(height: 14),
                        Text(
                          'Securing your session…',
                          style: TextStyle(
                            color: context.textMutedColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Powered by AirPak Express',
                          style: TextStyle(
                            color: context.textSubtleColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ThreeDotsLoader extends StatefulWidget {
  const _ThreeDotsLoader();
  @override
  State<_ThreeDotsLoader> createState() => _ThreeDotsLoaderState();
}

class _ThreeDotsLoaderState extends State<_ThreeDotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_c.value + i * 0.33) % 1.0;
            final scale = 0.6 + 0.4 * (math.sin(t * math.pi * 2).abs());
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 7 * scale,
              height: 7 * scale,
              decoration: BoxDecoration(
                color: AppColors.brand,
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

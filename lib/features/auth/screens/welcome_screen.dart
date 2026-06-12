import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/design_system.dart';
import '../../../app/router.dart';
import '../../../core/widgets/airpak_brand.dart';
import '../../../core/widgets/motion.dart';
import '../providers/auth_controller.dart';

/// First-time user welcome screen — three big illustrated cards
/// explaining the value prop, then "Get started".
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});
  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _pageCtl = PageController();
  int _idx = 0;
  late final List<Map<String, dynamic>> _pages = const [
    {
      'icon': Icons.public_rounded,
      'title': 'Ship anywhere',
      'subtitle':
          'We route through 14+ global carriers including DHL, FedEx, UPS, and USPS — so you only deal with us.',
      'gradient': [Color(0xFFDC2626), Color(0xFF991B1B)],
    },
    {
      'icon': Icons.bolt_rounded,
      'title': 'Pay with Airpak Coin',
      'subtitle':
          'Brand-native settlement token pegged 1:1 to USD. Fund with 15 fiat currencies. No surprises.',
      'gradient': [Color(0xFF0052FF), Color(0xFF1E40AF)],
    },
    {
      'icon': Icons.support_agent_rounded,
      'title': 'Real humans, 24/7',
      'subtitle':
          'Live chat with AirPak staff, Apple Intelligence-powered smart replies, and a 99.2% resolution rate.',
      'gradient': [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    },
  ];

  @override
  void dispose() {
    _pageCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      AirpakMark(size: 36),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            context.go(AppRoutes.portalDashboard),
                        child: Text('Skip',
                            style: TextStyle(
                                color: context.textMutedColor,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtl,
                    onPageChanged: (i) => setState(() => _idx = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) {
                      final p = _pages[i];
                      return _Page(page: p, index: i);
                    },
                  ),
                ),
                _Dots(count: _pages.length, current: _idx),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      _ContinueButton(
                        isLast: _idx == _pages.length - 1,
                        onPressed: () {
                          if (_idx < _pages.length - 1) {
                            _pageCtl.nextPage(
                              duration: const Duration(milliseconds: 360),
                              curve: Curves.easeOutCubic,
                            );
                          } else {
                            context.push(AppRoutes.login);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      // Quick skip — sign in as guest (demo) for
                      // instant portal access. Made more visible.
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            await ref
                                .read(authControllerProvider.notifier)
                                .signIn('demo@airpak-express.com', 'demo1234');
                            if (context.mounted) {
                              context.go(AppRoutes.portalDashboard);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: context.surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.borderColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flash_on_rounded,
                                    size: 16, color: AppColors.brand),
                                const SizedBox(width: 6),
                                Text(
                                  'Continue as guest (demo)',
                                  style: GoogleFonts.inter(
                                    color: AppColors.brand,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.login),
                        child: Text(
                          'Already have an account? Sign in',
                          style: GoogleFonts.inter(
                            color: context.textMutedColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Page extends StatelessWidget {
  final Map<String, dynamic> page;
  final int index;
  const _Page({required this.page, required this.index});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StaggeredFadeIn(
            index: index,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: (page['gradient'] as List).cast<Color>(),
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (page['gradient'] as List).cast<Color>()[0]
                          .withValues(alpha: 0.5),
                      blurRadius: 36,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(page['icon'] as IconData,
                    color: Colors.white, size: 76),
              ),
              const SizedBox(height: 32),
              Text(
                page['title'] as String,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                page['subtitle'] as String,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: context.textMutedColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFEF2F2), Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brand.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int current;
  const _Dots({required this.count, required this.current});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? AppColors.brand
                : context.borderColor,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final bool isLast;
  final VoidCallback onPressed;
  const _ContinueButton(
      {required this.isLast, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.40),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLast ? 'Get started' : 'Continue',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isLast
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

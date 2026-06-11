import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/design_system.dart';
import '../widgets/auth_widgets.dart';

/// Onboarding screen that asks the user to enable Face ID / Touch ID
/// for quick re-authentication. Shown right after the first successful
/// sign-in.
class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});
  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen>
    with TickerProviderStateMixin {
  bool _enabling = false;
  bool _enabled = false;
  late final AnimationController _scanCtl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _scanCtl.dispose();
    super.dispose();
  }

  Future<void> _enable() async {
    setState(() => _enabling = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() {
      _enabling = false;
      _enabled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenScaffold(
      onBack: () => context.pop(),
      showBackButton: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          _FaceIdHero(scan: _scanCtl, enabled: _enabled || _enabling),
          const SizedBox(height: 28),
          AuthHeading(
            title: 'Use Face ID next time',
            subtitle:
                'Sign in instantly with Face ID. Your password and personal data stay protected on this device.',
          ),
          const SizedBox(height: 28),
          _Benefit(
            icon: Icons.shield_rounded,
            title: 'Private & secure',
            body:
                'Face ID is processed on-device. AirPak never sees or stores your face data.',
          ),
          const SizedBox(height: 12),
          _Benefit(
            icon: Icons.bolt_rounded,
            title: 'Sign in 4× faster',
            body:
                'Skip typing your email and password. One glance and you\'re in.',
          ),
          const SizedBox(height: 12),
          _Benefit(
            icon: Icons.lock_outline_rounded,
            title: 'You stay in control',
            body:
                'Turn it off anytime in Settings · Account · Sign-in & Security.',
          ),
          const SizedBox(height: 30),
          AuthPrimaryButton(
            label: _enabled
                ? 'Continue'
                : _enabling
                    ? 'Scanning…'
                    : 'Enable Face ID',
            icon: _enabled ? Icons.check_rounded : Icons.face_rounded,
            onPressed: _enabled ? () => context.pop() : _enable,
            busy: _enabling,
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Text(
                'Not now',
                style: GoogleFonts.inter(
                  color: context.textMutedColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceIdHero extends StatelessWidget {
  final AnimationController scan;
  final bool enabled;
  const _FaceIdHero({required this.scan, required this.enabled});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulse rings
            AnimatedBuilder(
              animation: scan,
              builder: (_, __) {
                final t = scan.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(
                        width: 200 - i * 50,
                        height: 200 - i * 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.brand
                                .withValues(alpha: 0.18 - i * 0.05),
                            width: 1.4,
                          ),
                        ),
                      ),
                    if (enabled)
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.brand
                                  .withValues(alpha: 0.25 * t),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            // Center disc
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: enabled
                      ? [AppColors.success, const Color(0xFF059669)]
                      : [AppColors.brand, AppColors.brandDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (enabled
                            ? AppColors.success
                            : AppColors.brand)
                        .withValues(alpha: 0.45),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                enabled
                    ? Icons.check_rounded
                    : Icons.face_retouching_natural_rounded,
                color: Colors.white,
                size: 56,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Benefit(
      {required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.brand, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: context.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: GoogleFonts.inter(
                  color: context.textMutedColor,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

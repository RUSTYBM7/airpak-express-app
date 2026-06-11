import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/design_system.dart';
import '../../../app/router.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_widgets.dart';

/// Apple-style 6-digit OTP verification screen.
/// Used for both email verification and admin 2FA.
class OtpScreen extends ConsumerStatefulWidget {
  /// Destination email shown in the subtitle.
  final String email;
  /// Title shown at the top.
  final String title;
  /// Where to route on success.
  final String nextRoute;
  /// Called with the entered code on success — return true to advance.
  final Future<bool> Function(String code) onVerify;

  const OtpScreen({
    super.key,
    required this.email,
    required this.title,
    required this.nextRoute,
    required this.onVerify,
  });
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String _code = '';
  bool _busy = false;
  int _resendIn = 30;
  Timer? _timer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _resendIn = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_resendIn > 0) _resendIn--;
        if (_resendIn == 0) t.cancel();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _onCompleted(String code) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    // Haptic
    HapticFeedback.lightImpact();
    final ok = await widget.onVerify(code);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      HapticFeedback.mediumImpact();
      context.go(widget.nextRoute);
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _error = 'Incorrect code · please try again');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenScaffold(
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.45),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.mark_email_read_rounded,
                  color: Colors.white, size: 38),
            ),
          ),
          const SizedBox(height: 22),
          AuthHeading(
            title: widget.title,
            subtitle:
                'We sent a 6-digit verification code to ${widget.email}. Enter it below to continue.',
          ),
          const SizedBox(height: 30),
          OtpInput(
            onChanged: (c) => _code = c,
            onCompleted: _onCompleted,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            AuthErrorBanner(message: _error!),
          ],
          const SizedBox(height: 24),
          if (_busy)
            const Center(
                child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: AppColors.brand)))
          else
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    color: context.textMutedColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: "Didn't receive the code? "),
                    if (_resendIn > 0)
                      TextSpan(
                        text: 'Resend in ${_resendIn}s',
                        style: TextStyle(
                            color: context.textSubtleColor,
                            fontWeight: FontWeight.w800),
                      )
                    else
                      TextSpan(
                        text: 'Resend now',
                        style: TextStyle(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w800),
                        // ignore: deprecated_member_use
                        // (we use TextSpan's recognizer via GestureDetector wrapper below)
                      ),
                  ],
                ),
              ),
            ),
          if (_resendIn == 0) ...[
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: _startTimer,
                child: Text('Tap to resend',
                    style: GoogleFonts.inter(
                        color: AppColors.brand,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _DemoHintCard(),
        ],
      ),
    );
  }
}

class _DemoHintCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.bolt_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Demo mode',
                    style: TextStyle(
                        color: AppColors.brand,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3)),
                Text('Use 000000 to verify, or any 6 digits in mock mode.',
                    style: TextStyle(
                        color: context.textColor, fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

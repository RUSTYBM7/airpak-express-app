import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/design_system.dart';
import '../../../app/router.dart';
import '../providers/auth_controller.dart';
import '../services/auth_validators.dart';
import '../widgets/auth_widgets.dart';

/// Multi-step registration:
///   1. Account  — name + email + phone
///   2. Security — password + strength meter + terms
///   3. Profile  — company, country, role (shipper / carrier)
///   4. Verify   — 6-digit OTP
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _pageCtl = PageController();
  int _step = 0;

  // Step 1
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  // Step 2
  final _password = TextEditingController();
  bool _obscure = true;
  bool _agree = false;
  PasswordScore _pwd = const PasswordScore(
      strength: PasswordStrength.empty,
      fraction: 0,
      label: '',
      score: 0,
      feedback: []);
  // Step 3
  String _country = 'United States';
  String _role = 'Shipper';
  final _company = TextEditingController();
  // Step 4
  String _otp = '';

  late final List<AnimationController> _stepAnims;

  @override
  void initState() {
    super.initState();
    _stepAnims = List.generate(
      4,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      )..forward(),
    );
    _password.addListener(() {
      setState(() {
        _pwd = evaluatePassword(_password.text);
      });
    });
  }

  @override
  void dispose() {
    for (final c in _stepAnims) c.dispose();
    _pageCtl.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _company.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 3) {
      _stepAnims[_step + 1].forward(from: 0);
      setState(() => _step++);
      _pageCtl.nextPage(
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtl.previousPage(
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic);
    } else {
      context.pop();
    }
  }

  Future<void> _finish() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter the 6-digit code we sent you')));
      return;
    }
    final ok = await ref.read(authControllerProvider.notifier).register(
          email: _email.text.trim(),
          password: _password.text,
          fullName: _name.text.trim(),
          phone: _phone.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      context.go(AppRoutes.portalDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepLabels = const [
      'Account',
      'Security',
      'Profile',
      'Verify',
    ];
    return AuthScreenScaffold(
      onBack: _back,
      showBackButton: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          StepProgress(current: _step, total: 4, labels: stepLabels),
          const SizedBox(height: 24),
          SizedBox(
            height: 520,
            child: PageView(
              controller: _pageCtl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _stepAccount(),
                _stepSecurity(),
                _stepProfile(),
                _stepVerify(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: _GhostButton(
                    label: 'Back',
                    icon: Icons.arrow_back_rounded,
                    onTap: _back,
                  ),
                ),
              if (_step > 0) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: AuthPrimaryButton(
                  label: _step < 3 ? 'Continue' : 'Create account',
                  icon: _step < 3
                      ? Icons.arrow_forward_rounded
                      : Icons.check_rounded,
                  onPressed: _step < 3 ? _onPrimary : _finish,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  // ── Validation gate for current step ─────────────────────────────
  bool? _validateStep() {
    if (_step == 0) {
      if (_name.text.trim().isEmpty) return false;
      if (!_email.text.contains('@')) return false;
      if (_phone.text.trim().length < 7) return false;
      return true;
    }
    if (_step == 1) {
      if (_pwd.score < 2) return false;
      if (!_agree) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please agree to the Terms')));
        return false;
      }
      return true;
    }
    if (_step == 2) return true;
    return null;
  }

  void _onPrimary() {
    final v = _validateStep();
    if (v == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the required fields')),
      );
      return;
    }
    _next();
  }

  // ── Step 1: Account ─────────────────────────────────────────────
  Widget _stepAccount() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeading(
            title: 'Tell us who you are',
            subtitle:
                'We use these details to create your AirPak Express account and route shipments to you.',
          ),
          const SizedBox(height: 24),
          AuthTextField(
            controller: _name,
            label: 'FULL NAME',
            icon: Icons.person_outline_rounded,
            validator: (v) =>
                validateRequired(v, 'Full name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _email,
            label: 'EMAIL',
            icon: Icons.email_outlined,
            keyboard: TextInputType.emailAddress,
            validator: validateEmail,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _phone,
            label: 'PHONE',
            icon: Icons.phone_outlined,
            keyboard: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
            ],
            onChanged: (v) {
              _phone.text = formatPhone(v);
              _phone.selection = TextSelection.collapsed(
                  offset: _phone.text.length);
              setState(() {});
            },
            validator: validatePhone,
            helper: 'Include country code (e.g. +1 555 123 4567)',
          ),
        ],
      ),
    );
  }

  // ── Step 2: Security ────────────────────────────────────────────
  Widget _stepSecurity() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeading(
            title: 'Secure your account',
            subtitle:
                'Choose a strong password to protect your shipments and Airpak Coin balance.',
          ),
          const SizedBox(height: 24),
          AuthTextField(
            controller: _password,
            label: 'PASSWORD',
            icon: Icons.lock_outline_rounded,
            obscure: true,
            validator: validatePassword,
          ),
          PasswordStrengthMeter(score: _pwd),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surfaceMutedColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PwdHint(
                    ok: _pwd.score >= 1,
                    label: 'At least 8 characters'),
                _PwdHint(
                    ok: _pwd.score >= 2,
                    label: 'Mix of upper & lower case letters'),
                _PwdHint(
                    ok: _pwd.score >= 3, label: 'A number'),
                _PwdHint(
                    ok: _pwd.score >= 4,
                    label: 'A symbol (!@#\$%^&*)'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _agree,
                  onChanged: (v) => setState(() => _agree = v ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeColor: AppColors.brand,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  children: [
                    Text('I agree to the ',
                        style: TextStyle(
                            color: context.textColor, fontSize: 13)),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.terms),
                      child: Text('Terms of Service',
                          style: TextStyle(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ),
                    Text(' and ',
                        style: TextStyle(
                            color: context.textColor, fontSize: 13)),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.privacy),
                      child: Text('Privacy Policy',
                          style: TextStyle(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ),
                    Text('.',
                        style: TextStyle(
                            color: context.textColor, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step 3: Profile ─────────────────────────────────────────────
  Widget _stepProfile() {
    final countries = const [
      'United States',
      'United Kingdom',
      'Germany',
      'France',
      'Australia',
      'Canada',
      'Japan',
      'Singapore',
      'Indonesia',
      'United Arab Emirates',
      'Malaysia',
      'Brazil',
      'Mexico',
      'India',
      'Other',
    ];
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeading(
            title: 'Where are you shipping?',
            subtitle:
                'This helps us default to the right carriers and currencies. You can change it later.',
          ),
          const SizedBox(height: 24),
          AuthTextField(
            controller: _company,
            label: 'COMPANY NAME (OPTIONAL)',
            icon: Icons.business_rounded,
          ),
          const SizedBox(height: 14),
          _PickerField(
            label: 'PRIMARY COUNTRY',
            value: _country,
            icon: Icons.public_rounded,
            options: countries,
            onChanged: (v) => setState(() => _country = v),
          ),
          const SizedBox(height: 14),
          Text('WHAT DESCRIBES YOU BEST?',
              style: TextStyle(
                  color: context.textMutedColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _RoleChip(
                  label: 'Shipper',
                  icon: Icons.outbox_rounded,
                  selected: _role == 'Shipper',
                  onTap: () => setState(() => _role = 'Shipper'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RoleChip(
                  label: 'Carrier',
                  icon: Icons.local_shipping_rounded,
                  selected: _role == 'Carrier',
                  onTap: () => setState(() => _role = 'Carrier'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RoleChip(
                  label: 'Agent',
                  icon: Icons.support_agent_rounded,
                  selected: _role == 'Agent',
                  onTap: () => setState(() => _role = 'Agent'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step 4: Verify ──────────────────────────────────────────────
  Widget _stepVerify() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.4),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.mark_email_read_rounded,
                  color: Colors.white, size: 38),
            ),
          ),
          const SizedBox(height: 18),
          AuthHeading(
            title: 'Verify your email',
            subtitle:
                'We sent a 6-digit code to ${_email.text}. Enter it below to activate your account.',
          ),
          const SizedBox(height: 24),
          OtpInput(
            onChanged: (c) => _otp = c,
            onCompleted: (c) => _otp = c,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Didn\'t get it? ',
                  style: TextStyle(
                      color: context.textMutedColor, fontSize: 13)),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Code re-sent (demo: 000000)')));
                },
                child: Text('Resend',
                    style: TextStyle(
                        color: AppColors.brand,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DemoHintCard(),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────

class _PwdHint extends StatelessWidget {
  final bool ok;
  final String label;
  const _PwdHint({required this.ok, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: ok ? AppColors.success : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: ok ? AppColors.success : context.borderColor,
                width: 1.4,
              ),
            ),
            child: ok
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 12)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: ok ? context.textColor : context.textMutedColor,
              fontSize: 12.5,
              fontWeight: ok ? FontWeight.w700 : FontWeight.w500,
              decoration: ok ? TextDecoration.none : TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final IconData icon;
  final ValueChanged<String> onChanged;
  const _PickerField({
    required this.label,
    required this.value,
    required this.options,
    required this.icon,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label,
              style: TextStyle(
                color: context.textMutedColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              )),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final picked = await showModalBottomSheet<String>(
                context: context,
                backgroundColor: context.surfaceColor,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => ListView(
                  shrinkWrap: true,
                  children: [
                    for (final o in options)
                      ListTile(
                        title: Text(o),
                        trailing: o == value
                            ? const Icon(Icons.check_rounded,
                                color: AppColors.brand)
                            : null,
                        onTap: () => Navigator.of(context).pop(o),
                      ),
                  ],
                ),
              );
              if (picked != null) onChanged(picked);
            },
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Icon(icon, color: context.textMutedColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        color: context.textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.expand_more_rounded,
                      color: context.textMutedColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brand.withValues(alpha: 0.10)
                : context.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.brand
                  : context.borderColor,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: selected
                      ? AppColors.brand
                      : context.textMutedColor,
                  size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppColors.brand
                      : context.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GhostButton(
      {required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: context.textColor, size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ),
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
        border: Border.all(
            color: AppColors.brand.withValues(alpha: 0.30), width: 1),
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
                Text(
                    'Any 6-digit code is accepted. The server is in mock mode.',
                    style: TextStyle(
                        color: context.textColor,
                        fontSize: 11.5,
                        height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

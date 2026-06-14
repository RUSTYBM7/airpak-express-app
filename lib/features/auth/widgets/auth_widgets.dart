import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/design_system.dart';
import '../services/auth_validators.dart';

// ── Auth screen container ──────────────────────────────────────────────

/// Top-level chrome for an auth screen: a soft brand-tinted gradient
/// backdrop, two radial glow circles, and a SafeArea scroll view.
class AuthScreenScaffold extends StatelessWidget {
  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget> topRight;
  final Widget? footer;
  const AuthScreenScaffold({
    super.key,
    required this.child,
    this.showBackButton = true,
    this.onBack,
    this.topRight = const [],
    this.footer,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Brand gradient backdrop
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFEF2F2),
                  Color(0xFFFFFFFF),
                  Color(0xFFFAFAFA),
                ],
              ),
            ),
          ),
          // Glow orbs
          Positioned(
            top: -120,
            right: -80,
            child: _GlowOrb(
              size: 320,
              color: AppColors.brand,
              opacity: 0.10,
            ),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _GlowOrb(
              size: 360,
              color: AppColors.accent,
              opacity: 0.07,
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      if (showBackButton)
                        _CircleIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: onBack ??
                              () => Navigator.of(context).maybePop(),
                        ),
                      const Spacer(),
                      ...topRight,
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: child,
                  ),
                ),
                if (footer != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: footer!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowOrb(
      {required this.size, required this.color, required this.opacity});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: opacity), Colors.transparent],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
      ),
    );
  }
}

// ── Auth heading ───────────────────────────────────────────────────────

class AuthHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? illustration;
  const AuthHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.illustration,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (illustration != null) ...[
          Center(child: illustration!),
          const SizedBox(height: 24),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: context.textColor,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.textMutedColor,
            fontSize: 15,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

// ── Auth text field (iOS 17 style) ────────────────────────────────────

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboard;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final Widget? suffix;
  final String? helper;
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon = Icons.alternate_email_rounded,
    this.obscure = false,
    this.keyboard = TextInputType.text,
    this.validator,
    this.onChanged,
    this.inputFormatters,
    this.autofocus = false,
    this.suffix,
    this.helper,
  });
  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscure = widget.obscure;
  late bool _focused = false;
  final _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              widget.label,
              style: TextStyle(
                color: context.textMutedColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _focused ? AppColors.brand : context.borderColor,
              width: _focused ? 1.6 : 1,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.15),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: _focused
                      ? AppColors.brand
                      : context.textMutedColor,
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: _obscure,
                  keyboardType: widget.keyboard,
                  validator: widget.validator,
                  onChanged: widget.onChanged,
                  inputFormatters: widget.inputFormatters,
                  autofocus: widget.autofocus,
                  textInputAction: TextInputAction.next,
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    color: context.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: AppColors.brand,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                        color: context.textSubtleColor,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              if (widget.suffix != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: widget.suffix!,
                ),
              if (widget.obscure)
                IconButton(
                  splashRadius: 20,
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: context.textMutedColor,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
            ],
          ),
        ),
        if (widget.helper != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              widget.helper!,
              style: TextStyle(
                  color: context.textMutedColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Password strength meter ───────────────────────────────────────────

class PasswordStrengthMeter extends StatelessWidget {
  final PasswordScore score;
  const PasswordStrengthMeter({super.key, required this.score});
  @override
  Widget build(BuildContext context) {
    if (score.strength == PasswordStrength.empty) return const SizedBox.shrink();
    final color = _colorFor(score.strength);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: Stack(
                  children: [
                    Container(
                      height: 5,
                      color: context.borderColor,
                    ),
                    FractionallySizedBox(
                      widthFactor: score.fraction,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 5,
                        decoration: BoxDecoration(
                          color: color,
                          gradient: LinearGradient(
                            colors: [color.withValues(alpha: 0.6), color],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              score.label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        if (score.feedback.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final f in score.feedback)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.surfaceMutedColor,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 11, color: context.textMutedColor),
                      const SizedBox(width: 4),
                      Text(f,
                          style: TextStyle(
                              color: context.textMutedColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Color _colorFor(PasswordStrength s) {
    return switch (s) {
      PasswordStrength.weak => const Color(0xFFEF4444),
      PasswordStrength.fair => const Color(0xFFF59E0B),
      PasswordStrength.good => const Color(0xFF10B981),
      PasswordStrength.strong || PasswordStrength.excellent =>
        AppColors.brand,
      _ => AppColors.brand,
    };
  }
}

// ── SSO button ────────────────────────────────────────────────────────

class SsoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  final bool busy;
  const SsoButton({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
    this.busy = false,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.surfaceColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: color ?? AppColors.brand),
                )
              else
                Icon(icon, color: color ?? context.textColor, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Auth primary button ───────────────────────────────────────────────

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final String? sublabel;
  const AuthPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.busy = false,
    this.sublabel,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: busy ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.6, color: Colors.white))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (icon != null) ...[
                            const SizedBox(width: 8),
                            Icon(icon, color: Colors.white, size: 20),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
        if (sublabel != null) ...[
          const SizedBox(height: 8),
          Text(
            sublabel!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textMutedColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Step progress indicator (for multi-step register) ─────────────────

class StepProgress extends StatelessWidget {
  final int current;
  final int total;
  final List<String> labels;
  const StepProgress({
    super.key,
    required this.current,
    required this.total,
    required this.labels,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: i <= current
                        ? AppColors.brand
                        : context.borderColor,
                  ),
                ),
              ),
              if (i < total - 1) const SizedBox(width: 4),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'STEP ${current + 1} OF $total · ${labels[current].toUpperCase()}',
          style: TextStyle(
            color: AppColors.brand,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

// ── OTP input row (Apple-style 6-digit) ───────────────────────────────

class OtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;
  final bool autoFocus;
  const OtpInput({
    super.key,
    this.length = 6,
    required this.onChanged,
    required this.onCompleted,
    this.autoFocus = true,
  });
  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _ctrls;
  late final List<FocusNode> _nodes;
  String _code = '';

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
    for (var i = 0; i < widget.length; i++) {
      _nodes[i].addListener(() {
        if (mounted) setState(() {});
      });
    }
    _code = '';
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  void _onChanged(int idx, String v) {
    if (v.length > 1) {
      // paste handling
      final digits = v.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < digits.length && (idx + i) < widget.length; i++) {
        _ctrls[idx + i].text = digits[i];
        _ctrls[idx + i].selection =
            TextSelection.collapsed(offset: digits[i].length);
      }
      _emit();
      if ((idx + digits.length) < widget.length) {
        _nodes[idx + digits.length].requestFocus();
      } else {
        FocusScope.of(context).unfocus();
      }
      return;
    }
    if (v.isNotEmpty && idx < widget.length - 1) {
      _nodes[idx + 1].requestFocus();
    }
    _emit();
  }

  void _emit() {
    final code = _ctrls.map((c) => c.text).join();
    if (code != _code) {
      _code = code;
      widget.onChanged(code);
      if (code.length == widget.length) widget.onCompleted(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < widget.length; i++)
          Container(
            width: 48,
            height: 60,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _ctrls[i].text.isNotEmpty || _nodes[i].hasFocus
                    ? AppColors.brand
                    : context.borderColor,
                width:
                    _ctrls[i].text.isNotEmpty || _nodes[i].hasFocus ? 1.6 : 1,
              ),
            ),
            child: TextField(
              controller: _ctrls[i],
              focusNode: _nodes[i],
              autofocus: widget.autoFocus && i == 0,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: context.textColor,
                letterSpacing: -0.4,
              ),
              cursorColor: AppColors.brand,
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (v) => _onChanged(i, v),
              onSubmitted: (_) => _emit(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────

class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.danger),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

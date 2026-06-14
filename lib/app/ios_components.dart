import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';

import '../app/design_system.dart';

/// iOS-style design primitives — large titles, grouped inset lists,
/// SF-style toggles, translucent nav bars, etc.

/// Large iOS-style navigation title that collapses on scroll.
class LargeNavBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBack;
  const LargeNavBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 110,
      collapsedHeight: kToolbarHeight,
      backgroundColor: AppColors.surface, // overridden by surfaceColor in child
      surfaceTintColor: AppColors.surface,
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: context.textColor)),
      leading: showBack
          ? (leading ??
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ))
          : null,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: context.textColor,
          ),
        ),
        background: subtitle == null
            ? const SizedBox()
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textMutedColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Translucent blurred bar used at the top of overlay screens.
class IosBlurBar extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final Widget? leading;
  const IosBlurBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          color: context.surfaceColor.withValues(alpha: 0.72),
          padding:
              EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Row(
            children: [
              if (leading != null) leading!,
              Expanded(
                child: Center(
                  child: Text(title,
                      style: TextStyle(
fontSize: 17,
                          fontWeight: FontWeight.w600,
  color: context.textColor)),
                ),
              ),
              ...actions,
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// iOS-style inset-grouped section: a header label + a list of rounded
/// rows with hairline separators.
class IosSection extends StatelessWidget {
  final String? header;
  final List<IosRow> rows;
  final EdgeInsetsGeometry margin;
  const IosSection({
    super.key,
    this.header,
    required this.rows,
    this.margin = const EdgeInsets.fromLTRB(20, 22, 20, 0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Text(
                header!.toUpperCase(),
                style: TextStyle(
                  color: context.textMutedColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppElevation.xs,
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  rows[i],
                  if (i < rows.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 56),
                      child: Container(
                        height: 0.5,
                        color: context.dividerColor,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum IosTrailing {
  chevron,
  switch_,
  checkmark,
  check,
  custom,
  none,
}

/// Single row inside an [IosSection].
class IosRow extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String label;
  final String? sublabel;
  final IosTrailing trailing;
  final Widget? customTrailing;
  final VoidCallback? onTap;
  final Color? valueColor;
  final String? value;
  final bool destructive;
  final Widget? leading;
  const IosRow({
    super.key,
    this.icon,
    this.iconColor,
    required this.label,
    this.sublabel,
    this.trailing = IosTrailing.chevron,
    this.customTrailing,
    this.onTap,
    this.value,
    this.valueColor,
    this.destructive = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final c = iconColor ?? AppColors.brand;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              if (icon != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c, c.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: destructive ? AppColors.danger : context.textColor,
                      ),
                    ),
                    if (sublabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          sublabel!,
                          style: TextStyle(
                              color: context.textMutedColor, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
              if (value != null) ...[
                Text(
                  value!,
                  style: TextStyle(
                    color: valueColor ?? context.textMutedColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              _trailingWidget(context),
              const SizedBox(width: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trailingWidget(BuildContext context) {
    switch (trailing) {
      case IosTrailing.chevron:
        return Icon(Icons.chevron_right_rounded,
            color: context.textSubtleColor, size: 18);
      case IosTrailing.switch_:
        return const _FakeSwitch();
      case IosTrailing.checkmark:
        return const Icon(Icons.check_rounded,
            color: AppColors.brand, size: 18);
      case IosTrailing.check:
        return const Icon(Icons.check_rounded,
            color: AppColors.brand, size: 18);
      case IosTrailing.custom:
        return customTrailing ?? const SizedBox.shrink();
      case IosTrailing.none:
        return const SizedBox.shrink();
    }
  }
}

class _FakeSwitch extends StatelessWidget {
  const _FakeSwitch();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 2,
            bottom: 2,
            right: 2,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Real iOS-style switch (CupertinoSwitch styled to look native).
class IosSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const IosSwitch({super.key, required this.value, this.onChanged});
  @override
  Widget build(BuildContext context) {
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.success,
    );
  }
}

/// iOS-style large button (filled, full width, rounded, with icon).
class IosPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final bool destructive;
  const IosPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.busy = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: destructive ? AppColors.danger : AppColors.brand,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(Colors.white)),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// iOS-style secondary (text-like) button.
class IosTextButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  const IosTextButton(this.label,
      {super.key, this.icon, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? AppColors.brand,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
    );
  }
}

/// iOS-style text field: no filled background, hairline border, no
/// floating label — just a clean rounded rectangle.
class IosTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final bool obscure;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  const IosTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      textCapitalization: textCapitalization,
      validator: validator,
      autofocus: autofocus,
      maxLines: obscure ? 1 : maxLines,
      minLines: minLines,
      style: TextStyle(fontSize: 16, color: context.textColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
      ),
    );
  }
}

/// iOS-style status pill with a coloured background and dot.
class IosStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const IosStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1)),
        ],
      ),
    );
  }
}

/// Translucent bottom sheet with rounded top — iOS modal style.
Future<T?> showIosSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = false,
  double initialChildSize = 0.6,
  double minChildSize = 0.2,
  double maxChildSize = 0.95,
  String? title,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: false,
      builder: (_, controller) => ClipRRect(
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: context.surfaceColor.withValues(alpha: 0.98),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                if (title != null) ...[
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textColor)),
                  const SizedBox(height: 14),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

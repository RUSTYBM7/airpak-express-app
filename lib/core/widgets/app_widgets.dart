import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../../app/design_system.dart';
import 'airpak_brand.dart';

/// ── Buttons ─────────────────────────────────────────────────────────

/// Primary CTA — gradient background, soft shadow, optional icon.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final bool expand;
  final Gradient? gradient;
  final bool dense;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.busy = false,
    this.expand = true,
    this.gradient,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.white),
                const Gap(8),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          );

    return Opacity(
      opacity: onPressed == null ? 0.5 : 1.0,
      child: Container(
        width: expand ? double.infinity : null,
        height: dense ? 44 : 54,
        decoration: BoxDecoration(
          gradient: gradient ?? AppColors.brandGradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: busy ? null : onPressed,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Secondary action — outlined, brand colour.
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;
  final bool dense;
  const AppSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.expand = true,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : null,
      height: dense ? 44 : 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.brand, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppColors.brand),
              const Gap(8),
            ],
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Tertiary action — text only, brand colour.
class AppTextButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  const AppTextButton(this.label, {super.key, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 16) : const SizedBox.shrink(),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

/// Pill-shaped, dark glass button.
class AppGlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  const AppGlassButton({super.key, required this.label, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.overlay,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: Colors.white),
                const Gap(6),
              ],
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

/// ── Cards ───────────────────────────────────────────────────────────

/// Default surface card — white, hairline border, soft shadow.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;
  final double radius;
  final List<BoxShadow>? shadow;
  final Gradient? gradient;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.xxl),
    this.onTap,
    this.color,
    this.border,
    this.radius = AppRadius.lg,
    this.shadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: gradient == null
                ? (color ?? context.surfaceColor)
                : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius),
            border: border ?? Border.all(color: context.borderColor, width: 1),
            boxShadow: shadow ?? context.cardShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Subtle stat tile — small, hairline border, generous padding.
class AppStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final Color iconColor;
  final String? trend;
  final bool positive;
  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.gradient = AppColors.brandGradient,
    this.iconColor = AppColors.brand,
    this.trend,
    this.positive = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: positive ? AppColors.successSoft : AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        positive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 12,
                        color: positive ? AppColors.success : AppColors.danger,
                      ),
                      const Gap(4),
                      Text(
                        trend!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: positive ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Gap(AppSpace.xxl),
          Text(value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.0,
                letterSpacing: -0.6,
                color: context.textColor,
              )),
          const Gap(AppSpace.xs),
          Text(label,
              style: TextStyle(
                color: context.textMutedColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              )),
        ],
      ),
    );
  }
}

/// Horizontal metric row with a sparkline / value emphasis.
class AppMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const AppMetricRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.brand,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const Gap(AppSpace.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      color: context.textMutedColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3)),
              const Gap(2),
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: context.textColor)),
            ],
          ),
        ),
      ],
    );
  }
}

/// ── Headers / dividers ─────────────────────────────────────────────

/// Eyebrow section header with a brand red bar.
class SectionHeader extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;
  const SectionHeader(
    this.text, {
    super.key,
    this.action,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(0, 24, 0, 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(AppSpace.md),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: context.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const Spacer(),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(action!,
                  style: const TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

/// Brand logo block — renders the official AirPak Express monogram
/// (the red rounded-square mark from `assets/brand/airpak_mark.svg`).
class BrandMark extends StatelessWidget {
  final double size;
  final IconData icon;
  final Gradient gradient;
  const BrandMark({
    super.key,
    this.size = 40,
    this.icon = Icons.local_shipping_rounded,
    this.gradient = AppColors.brandGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.10),
        child: AirpakMark(size: size * 0.62, fg: Colors.white),
      ),
    );
  }
}

/// ── Status pills ────────────────────────────────────────────────────

/// Pill-shaped status indicator with coloured background + dot.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? bg;
  final IconData? icon;
  final bool dense;
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.bg,
    this.icon,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg ?? color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: dense ? 10 : 12),
            const Gap(4),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const Gap(6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: dense ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Status states (mapping) ────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Gradient? gradient;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: gradient ?? AppColors.brandGradient,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const Gap(20),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: context.textColor)),
            if (subtitle != null) ...[
              const Gap(8),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.textMutedColor)),
            ],
            if (action != null) ...[const Gap(20), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  final Object? error;
  final VoidCallback? onRetry;
  const ErrorStateView({super.key, this.error, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.error_outline,
                  color: AppColors.danger, size: 28),
            ),
            const Gap(16),
            Text('Something went wrong',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: context.textColor)),
            const Gap(8),
            Text(
              error?.toString() ?? 'Please try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.textMutedColor, fontSize: 13),
            ),
            if (onRetry != null) ...[
              const Gap(20),
              AppPrimaryButton(
                  label: 'Retry', icon: Icons.refresh, onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}

/// ── Misc helpers ───────────────────────────────────────────────────

/// Click-to-copy inline field. Shows a small snackbar on copy.
class CopyableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const CopyableText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: text));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied to clipboard'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
            margin: EdgeInsets.all(AppSpace.xxl),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppSpace.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child:
                  Text(text, style: style, overflow: TextOverflow.ellipsis),
            ),
            const Gap(6),
            Icon(Icons.copy_rounded,
                size: 12, color: context.textMutedColor),
          ],
        ),
      ),
    );
  }
}

/// Soft progress bar with rounded ends.
class SoftProgress extends StatelessWidget {
  final double value;
  final Color color;
  final Color track;
  final double height;
  const SoftProgress({
    super.key,
    required this.value,
    this.color = AppColors.brand,
    this.track = AppColors.brandSoft,
    this.height = 8,
  });
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        backgroundColor: track,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

/// Generic icon tile (used in lists, quick actions).
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconTile({
    super.key,
    required this.icon,
    this.color = AppColors.brand,
    this.size = 40,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

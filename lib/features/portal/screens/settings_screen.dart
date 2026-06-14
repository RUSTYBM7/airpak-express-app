import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/cupertino.dart';
import '../../../app/design_system.dart';
import '../../../app/ios_components.dart';
import '../../../app/router.dart';
import '../../../app/theme_provider.dart';
import '../../../core/models/carrier.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/carrier_logo.dart';
import '../../../core/widgets/motion.dart';
import '../../auth/providers/auth_controller.dart';
import '../../settings/settings_controller.dart';

/// iOS 17 Pro Max Settings — every section follows Apple's column
/// alignment rules. Every toggle, picker, and field is **real-time**:
/// state changes are written through `SettingsController` and
/// immediately reflected on the page (and persisted to disk).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final p = auth.profile;
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            IosLargeNavBar(
              title: 'Settings',
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.search_rounded, color: context.textMutedColor, size: 22),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  if (p != null) _ProfileHeader(name: p.displayName, email: p.email, company: p.companyName),
                  const SizedBox(height: 24),
                  _section(context, 'Apple ID, iCloud and Media & Purchases'),
                  _GroupedCard(
                    rows: [
                      IosRow(
                        icon: Icons.person_rounded,
                        label: p?.displayName ?? 'You',
                        sublabel: 'Apple ID, iCloud, Media & Purchases',
                        onTap: () => context.push(AppRoutes.portalProfile),
                      ),
                      IosRow(
                        icon: Icons.family_restroom_rounded,
                        iconColor: const Color(0xFFFF9500),
                        label: 'Family Sharing',
                        onTap: () {},
                      ),
                    ],
                  ),
                  _section(context, 'AirPak Services'),
                  _GroupedCard(
                    rows: [
                      IosRow(
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: const Color(0xFF0052FF),
                        label: 'Invoice & Wallet',
                        value: 'Deposit · Pay',
                        onTap: () => context.go(AppRoutes.portalPayments),
                      ),
                      IosRow(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFFFCC00),
                        label: 'Rewards & Referrals',
                        value: '${p?.rewardPoints ?? 0} pts',
                        onTap: () => context.go(AppRoutes.portalRewards),
                      ),
                      IosRow(
                        icon: Icons.local_shipping_rounded,
                        iconColor: AppColors.brand,
                        label: 'Default Carrier',
                        value: settings.defaultCarrier,
                        trailing: IosTrailing.custom,
                        customTrailing: _CarrierChip(id: settings.defaultCarrier),
                        onTap: () => _showCarriers(context, ref),
                      ),
                      _LiveSwitch(
                        icon: Icons.payments_rounded,
                        iconColor: AppColors.brand,
                        label: 'Auto-pay with Airpak Coin',
                        sublabel: 'Use APC balance to settle shipping',
                        value: settings.autoPayWithCoin,
                        onChanged: (v) {
                          ref.read(settingsControllerProvider.notifier).setAutoPayWithCoin(v);
                          HapticService.success();
                        },
                      ),
                    ],
                  ),
                  _section(context, 'Connected Services'),
                  _GroupedCard(
                    rows: [
                      IosRow(
                        icon: Icons.credit_card_rounded,
                        iconColor: const Color(0xFF34C759),
                        label: 'Payment Methods',
                        trailing: IosTrailing.none,
                        onTap: () => _showAddCard(context, ref),
                      ),
                      IosRow(
                        icon: Icons.public_rounded,
                        iconColor: const Color(0xFF5856D6),
                        label: 'Default Currency',
                        value: settings.defaultCurrency,
                        onTap: () => _showCurrencies(context, ref),
                      ),
                      IosRow(
                        icon: Icons.language_rounded,
                        iconColor: const Color(0xFF007AFF),
                        label: 'Language',
                        value: settings.language,
                        onTap: () => _showLanguages(context, ref),
                      ),
                    ],
                  ),
                  _section(context, 'Notifications'),
                  _GroupedCard(
                    rows: [
                      _LiveSwitch(
                        icon: Icons.notifications_active_rounded,
                        iconColor: const Color(0xFFFF3B30),
                        label: 'Push notifications',
                        sublabel: 'Real-time updates on your device',
                        value: settings.pushEnabled,
                        onChanged: (v) {
                          ref.read(settingsControllerProvider.notifier).setPush(v);
                          HapticService.selection();
                        },
                      ),
                      _LiveSwitch(
                        icon: Icons.email_rounded,
                        iconColor: const Color(0xFF007AFF),
                        label: 'Email',
                        sublabel: 'Receipts, tracking, marketing',
                        value: settings.emailEnabled,
                        onChanged: (v) => ref.read(settingsControllerProvider.notifier).setEmail(v),
                      ),
                      _LiveSwitch(
                        icon: Icons.sms_rounded,
                        iconColor: const Color(0xFF34C759),
                        label: 'SMS',
                        sublabel: 'Critical updates only',
                        value: settings.smsEnabled,
                        onChanged: (v) => ref.read(settingsControllerProvider.notifier).setSms(v),
                      ),
                      const _Divider(),
                      _LiveSwitch(
                        icon: Icons.local_shipping_rounded,
                        iconColor: AppColors.brand,
                        label: 'Shipment updates',
                        sublabel: 'Picked up, in transit, delivered',
                        value: settings.shipmentUpdates,
                        onChanged: (v) => ref.read(settingsControllerProvider.notifier).setShipmentUpdates(v),
                      ),
                      _LiveSwitch(
                        icon: Icons.trending_up_rounded,
                        iconColor: AppColors.warning,
                        label: 'Price alerts',
                        sublabel: 'Cheaper rates for saved routes',
                        value: settings.priceAlerts,
                        onChanged: (v) => ref.read(settingsControllerProvider.notifier).setPriceAlerts(v),
                      ),
                      _LiveSwitch(
                        icon: Icons.campaign_rounded,
                        iconColor: AppColors.info,
                        label: 'Newsletter',
                        sublabel: 'AirPak news, product updates',
                        value: settings.newsletter,
                        onChanged: (v) => ref.read(settingsControllerProvider.notifier).setNewsletter(v),
                      ),
                    ],
                  ),
                  _section(context, 'Privacy & Security'),
                  _GroupedCard(
                    rows: [
                      _LiveSwitch(
                        icon: Icons.shield_rounded,
                        iconColor: const Color(0xFFFF9500),
                        label: 'Two-Factor Authentication',
                        sublabel: settings.twoFactor ? 'Required at sign-in' : 'Off — not recommended',
                        value: settings.twoFactor,
                        onChanged: (v) {
                          ref.read(settingsControllerProvider.notifier).set2FA(v);
                          HapticService.medium();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(v ? '2FA enabled' : '2FA disabled')),
                          );
                        },
                      ),
                      _LiveSwitch(
                        icon: Icons.fingerprint_rounded,
                        iconColor: const Color(0xFF34C759),
                        label: 'Face ID',
                        sublabel: 'Unlock with biometrics',
                        value: settings.faceId,
                        onChanged: (v) => ref.read(settingsControllerProvider.notifier).setFaceId(v),
                      ),
                      _LiveSwitch(
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: AppColors.success,
                        label: 'Biometric payments',
                        sublabel: 'Confirm payments with Face ID',
                        value: settings.biometricPayments,
                        onChanged: (v) => ref.read(settingsControllerProvider.notifier).setBiometricPayments(v),
                      ),
                      _LiveSwitch(
                        icon: Icons.analytics_rounded,
                        iconColor: const Color(0xFF8E8E93),
                        label: 'Share analytics',
                        sublabel: 'Help us improve AirPak',
                        value: settings.analyticsOptIn,
                        onChanged: (v) => ref.read(settingsControllerProvider.notifier).setAnalytics(v),
                      ),
                      IosRow(
                        icon: Icons.devices_rounded,
                        iconColor: const Color(0xFF8E8E93),
                        label: 'Active Sessions',
                        value: '2 devices',
                        trailing: IosTrailing.none,
                        onTap: () => _showSessions(context),
                      ),
                    ],
                  ),
                  _section(context, 'Appearance'),
                  _GroupedCard(
                    rows: [
                      IosRow(
                        icon: themeMode == AppThemeMode.dark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        iconColor: const Color(0xFF8E8E93),
                        label: 'Appearance',
                        sublabel: 'Following: ${_label(themeMode)}',
                        trailing: IosTrailing.none,
                        onTap: () => _showAppearance(context, ref, themeMode),
                      ),
                      IosRow(
                        icon: Icons.palette_rounded,
                        iconColor: const Color(0xFFFF2D55),
                        label: 'Accent Color',
                        value: settings.accentColor.toUpperCase(),
                        trailing: IosTrailing.none,
                        onTap: () => _showAccent(context, ref),
                      ),
                      IosRow(
                        icon: Icons.format_size_rounded,
                        iconColor: const Color(0xFF007AFF),
                        label: 'Text Size',
                        value: settings.textSize.toUpperCase(),
                        trailing: IosTrailing.none,
                        onTap: () => _showTextSize(context, ref),
                      ),
                      _LiveSwitch(
                        icon: Icons.animation_rounded,
                        iconColor: AppColors.info,
                        label: 'Reduce motion',
                        sublabel: 'Minimize animations system-wide',
                        value: settings.reduceMotion,
                        onChanged: (v) => ref.read(settingsControllerProvider.notifier).setReduceMotion(v),
                      ),
                      _LiveSwitch(
                        icon: Icons.vibration_rounded,
                        iconColor: const Color(0xFFFF3B30),
                        label: 'Haptics',
                        sublabel: 'Tactile feedback on taps',
                        value: settings.haptics,
                        onChanged: (v) => ref.read(settingsControllerProvider.notifier).setHaptics(v),
                      ),
                    ],
                  ),
                  _section(context, 'General'),
                  _GroupedCard(
                    rows: [
                      IosRow(
                        icon: Icons.info_rounded,
                        iconColor: const Color(0xFF007AFF),
                        label: 'About',
                        trailing: IosTrailing.none,
                        onTap: () => _showAbout(context),
                      ),
                      IosRow(
                        icon: Icons.lock_outline_rounded,
                        iconColor: const Color(0xFF8E8E93),
                        label: 'Privacy Policy',
                        trailing: IosTrailing.none,
                        onTap: () => context.push(AppRoutes.privacy),
                      ),
                      IosRow(
                        icon: Icons.description_rounded,
                        iconColor: const Color(0xFF8E8E93),
                        label: 'Terms of Service',
                        trailing: IosTrailing.none,
                        onTap: () => context.push(AppRoutes.terms),
                      ),
                      IosRow(
                        icon: Icons.logout_rounded,
                        iconColor: const Color(0xFFFF3B30),
                        label: 'Sign Out',
                        destructive: true,
                        trailing: IosTrailing.none,
                        onTap: () async {
                          await ref.read(authControllerProvider.notifier).signOut();
                          if (context.mounted) context.go(AppRoutes.home);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Text('AirPak Express v11.0',
                            style: TextStyle(fontSize: 12, color: context.textMutedColor)),
                        const SizedBox(height: 4),
                        Text('Built by AirPak · ${DateTime.now().year}',
                            style: TextStyle(fontSize: 10, color: context.textSubtleColor)),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _label(AppThemeMode m) {
    switch (m) {
      case AppThemeMode.system: return 'System';
      case AppThemeMode.light: return 'Light';
      case AppThemeMode.dark: return 'Dark';
    }
  }

  Widget _section(BuildContext context, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 20, 6),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: context.textMutedColor,
            letterSpacing: 0.3,
          ),
        ),
      );
}

class _LiveSwitch extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String? sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _LiveSwitch({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.sublabel,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return IosRow(
      icon: icon,
      iconColor: iconColor,
      label: label,
      sublabel: sublabel,
      trailing: IosTrailing.switch_,
      onTap: () => onChanged(!value),
    );
  }
}

class _GroupedCard extends StatelessWidget {
  final List<Widget> rows;
  const _GroupedCard({required this.rows});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1 && rows[i] is! _Divider)
              const Padding(
                padding: EdgeInsets.only(left: 56),
                child: _Divider(),
              ),
          ],
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Container(height: 0.4, color: context.dividerColor);
  }
}

class _CarrierChip extends StatelessWidget {
  final String id;
  const _CarrierChip({required this.id});
  @override
  Widget build(BuildContext context) {
    final c = findCarrier(id) ?? kWorldwideCarriers.first;
    return CarrierLogo(carrier: c, size: 28);
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String company;
  const _ProfileHeader({required this.name, required this.email, required this.company});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brandGradient,
                boxShadow: [
                  BoxShadow(color: AppColors.brand.withValues(alpha: 0.30), blurRadius: 18, offset: const Offset(0, 6)),
                ],
              ),
              child: Center(
                child: Text(
                  name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 30),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: context.textColor, letterSpacing: -0.4)),
            const SizedBox(height: 2),
            Text(email, style: TextStyle(fontSize: 13, color: context.textMutedColor)),
            if (company.isNotEmpty) Text(company, style: TextStyle(fontSize: 12, color: context.textSubtleColor)),
          ],
        ),
      ),
    );
  }
}

// ── Modals ────────────────────────────────────────────────────────

String _themeLabel(AppThemeMode m) {
  switch (m) {
    case AppThemeMode.system: return 'System';
    case AppThemeMode.light: return 'Light';
    case AppThemeMode.dark: return 'Dark';
  }
}

void _showAddCard(BuildContext context, WidgetRef ref) {
  final num = TextEditingController();
  final exp = TextEditingController();
  final cvc = TextEditingController();
  showIosSheet(
    context: context,
    title: 'Add payment method',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IosTextField(controller: num, hint: 'Card number', prefixIcon: Icons.credit_card_rounded, keyboardType: TextInputType.number),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: IosTextField(controller: exp, hint: 'MM/YY', prefixIcon: Icons.calendar_today_rounded)),
          const SizedBox(width: 10),
          Expanded(child: IosTextField(controller: cvc, hint: 'CVC', prefixIcon: Icons.lock_rounded, keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 16),
        IosPrimaryButton(
          label: 'Save card',
          icon: Icons.check_rounded,
          onPressed: () {
            HapticService.success();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Card saved (mock)')),
            );
          },
        ),
      ],
    ),
  );
}

void _showCurrencies(BuildContext context, WidgetRef ref) {
  final c = ['USD', 'EUR', 'GBP', 'JPY', 'CNY', 'AUD', 'SGD', 'MYR', 'HKD', 'KRW', 'INR', 'AED', 'SAR'];
  showIosSheet(
    context: context,
    title: 'Default currency',
    child: Column(
      children: [
        for (final x in c)
          IosRow(
            icon: Icons.public_rounded,
            label: x,
            trailing: IosTrailing.check,
            onTap: () {
              ref.read(settingsControllerProvider.notifier).setDefaultCurrency(x);
              HapticService.selection();
              Navigator.pop(context);
            },
          ),
      ],
    ),
  );
}

void _showLanguages(BuildContext context, WidgetRef ref) {
  final langs = ['English (US)', 'English (UK)', 'Español', 'Français', 'Deutsch', '中文 (简体)', '中文 (繁體)', '日本語', '한국어', 'Bahasa Melayu', 'Bahasa Indonesia', 'العربية'];
  showIosSheet(
    context: context,
    title: 'Language',
    child: Column(
      children: [
        for (final l in langs)
          IosRow(
            icon: Icons.language_rounded,
            label: l,
            trailing: IosTrailing.check,
            onTap: () {
              ref.read(settingsControllerProvider.notifier).setLanguage(l);
              HapticService.selection();
              Navigator.pop(context);
            },
          ),
      ],
    ),
  );
}

void _showCarriers(BuildContext context, WidgetRef ref) {
  showIosSheet(
    context: context,
    title: 'Default carrier',
    child: Column(
      children: [
        for (final c in kWorldwideCarriers)
          IosRow(
            icon: Icons.local_shipping_rounded,
            iconColor: c.brandColor,
            label: c.name,
            sublabel: '${c.country} · ${c.eta}',
            trailing: IosTrailing.check,
            onTap: () {
              ref.read(settingsControllerProvider.notifier).setDefaultCarrier(c.name);
              HapticService.selection();
              Navigator.pop(context);
            },
          ),
      ],
    ),
  );
}

void _showAppearance(BuildContext context, WidgetRef ref, AppThemeMode current) {
  showIosSheet(
    context: context,
    title: 'Appearance',
    child: Column(
      children: [
        for (final m in AppThemeMode.values)
          IosRow(
            icon: m == AppThemeMode.dark
                ? Icons.dark_mode_rounded
                : m == AppThemeMode.light
                    ? Icons.light_mode_rounded
                    : Icons.brightness_auto_rounded,
            iconColor: m == AppThemeMode.dark
                ? AppColors.info
                : m == AppThemeMode.light
                    ? AppColors.warning
                    : const Color(0xFF8E8E93),
            label: _themeLabel(m),
            sublabel: m == AppThemeMode.system ? 'Follow device setting' : 'Always use this',
            trailing: current == m ? IosTrailing.check : IosTrailing.none,
            onTap: () {
              ref.read(themeControllerProvider.notifier).set(m);
              HapticService.selection();
              Navigator.pop(context);
            },
          ),
      ],
    ),
  );
}

void _showAccent(BuildContext context, WidgetRef ref) {
  final colors = ['red', 'orange', 'yellow', 'green', 'blue', 'indigo', 'purple', 'pink', 'teal'];
  final colorMap = {
    'red': AppColors.brand, 'orange': const Color(0xFFFF9500), 'yellow': const Color(0xFFFFCC00),
    'green': const Color(0xFF34C759), 'blue': const Color(0xFF007AFF), 'indigo': const Color(0xFF5856D6),
    'purple': const Color(0xFFAF52DE), 'pink': const Color(0xFFFF2D55), 'teal': const Color(0xFF5AC8FA),
  };
  showIosSheet(
    context: context,
    title: 'Accent color',
    child: Wrap(
      spacing: 14, runSpacing: 14,
      children: [
        for (final c in colors)
          GestureDetector(
            onTap: () {
              ref.read(settingsControllerProvider.notifier).setAccentColor(c);
              HapticService.success();
              Navigator.pop(context);
            },
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: colorMap[c],
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: colorMap[c]!.withValues(alpha: 0.4), blurRadius: 10)],
              ),
            ),
          ),
      ],
    ),
  );
}

void _showTextSize(BuildContext context, WidgetRef ref) {
  showIosSheet(
    context: context,
    title: 'Text size',
    child: Column(
      children: [
        for (final s in ['small', 'medium', 'large', 'extra-large'])
          IosRow(
            icon: Icons.format_size_rounded,
            iconColor: const Color(0xFF007AFF),
            label: s.toUpperCase(),
            trailing: IosTrailing.check,
            onTap: () {
              ref.read(settingsControllerProvider.notifier).setTextSize(s);
              HapticService.selection();
              Navigator.pop(context);
            },
          ),
      ],
    ),
  );
}

void _showNotifications(BuildContext context, WidgetRef ref, AuthState auth) {
  showIosSheet(
    context: context,
    title: 'Notifications',
    child: Column(
      children: const [
        IosRow(icon: Icons.notifications_active_rounded, iconColor: Color(0xFFFF3B30), label: 'Push', sublabel: 'Real-time updates', trailing: IosTrailing.switch_),
        IosRow(icon: Icons.email_rounded, iconColor: Color(0xFF007AFF), label: 'Email', sublabel: 'Receipts, tracking, marketing', trailing: IosTrailing.switch_),
        IosRow(icon: Icons.sms_rounded, iconColor: Color(0xFF34C759), label: 'SMS', sublabel: 'Critical updates only', trailing: IosTrailing.switch_),
      ],
    ),
  );
}

void _showSessions(BuildContext context) {
  showIosSheet(
    context: context,
    title: 'Active sessions',
    child: Column(
      children: const [
        IosRow(icon: Icons.phone_iphone_rounded, iconColor: Color(0xFF007AFF), label: 'iPhone 15 Pro', sublabel: 'Singapore · last active 2 min ago', trailing: IosTrailing.custom, customTrailing: Text('Current', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w800))),
        IosRow(icon: Icons.laptop_mac_rounded, iconColor: Color(0xFF8E8E93), label: 'MacBook Air M3', sublabel: 'Singapore · last active 4 hr ago', trailing: IosTrailing.custom, customTrailing: Text('Sign out', style: TextStyle(color: AppColors.brand, fontSize: 11, fontWeight: FontWeight.w800))),
      ],
    ),
  );
}

void _showAbout(BuildContext context) {
  showIosSheet(
    context: context,
    title: 'About AirPak Express',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 64, height: 64,
            decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text('A', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800))),
          ),
        ),
        SizedBox(height: 12),
        Center(child: Text('AirPak Express v11.0', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
        Center(child: Text('Global logistics platform', style: TextStyle(fontSize: 12, color: AppColors.textMuted))),
        SizedBox(height: 12),
        Text(
          'AirPak Express is a global logistics platform routing shipments through 14 partner carriers across 220 destinations. Real-time WebSocket tracking, Apple Intelligence support, and Airpak Coin (APC) settlement.',
          style: TextStyle(fontSize: 12.5, height: 1.55, color: AppColors.textBody),
        ),
        SizedBox(height: 14),
        IosPrimaryButton(label: 'Done', icon: Icons.check_rounded, onPressed: () => Navigator.pop(context)),
      ],
    ),
  );
}

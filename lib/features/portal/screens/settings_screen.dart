import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/cupertino.dart';
import '../../../app/design_system.dart';
import '../../../app/ios_components.dart';
import '../../../app/router.dart';
import '../../../app/theme_provider.dart';
import '../../../core/models/airpak_coin.dart';
import '../../../core/models/carrier.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/carrier_logo.dart';
import '../../../core/widgets/motion.dart';
import '../../auth/providers/auth_controller.dart';

/// iOS 17 Pro Max Settings — every section follows Apple's column
/// alignment rules: header in uppercase letter-spaced small caps, then
/// a grouped list of rows with leading icon tile + value + chevron.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final p = auth.profile;
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const IosLargeNavBar(
              title: 'Settings',
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.search_rounded,
                      color: AppColors.brand, size: 22),
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
                  _IosGroupedCard(
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
                  _IosGroupedCard(
                    rows: [
                      IosRow(
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: const Color(0xFF0052FF),
                        label: 'Airpak Coin',
                        value: 'Buy · Deposit · Pay',
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
                        value: 'DHL Express',
                        trailing: IosTrailing.custom,
                        customTrailing: const CarrierLogo(
                          carrier: Carrier(id: 'dhl', name: 'DHL', tagline: '', country: 'DE', currencyCode: 'EUR', flag: '🇩🇪', brandColor: Color(0xFFFFCC00), icon: Icons.flight_takeoff_rounded, rating: 4.7, eta: '2–5 days', logoAsset: 'assets/carriers/dhl.svg'),
                          size: 28,
                        ),
                        onTap: () => _showCarriers(context),
                      ),
                    ],
                  ),
                  _section(context, 'Connected Services'),
                  _IosGroupedCard(
                    rows: [
                      IosRow(
                        icon: Icons.credit_card_rounded,
                        iconColor: const Color(0xFF34C759),
                        label: 'Payment Methods',
                        trailing: IosTrailing.none,
                        onTap: () => _showAddCard(context),
                      ),
                      IosRow(
                        icon: Icons.public_rounded,
                        iconColor: const Color(0xFF5856D6),
                        label: 'Default Currency',
                        value: 'USD',
                        onTap: () => _showCurrencies(context),
                      ),
                      IosRow(
                        icon: Icons.language_rounded,
                        iconColor: const Color(0xFF007AFF),
                        label: 'Language',
                        value: 'English (US)',
                        onTap: () => _showLanguages(context),
                      ),
                    ],
                  ),
                  _section(context, 'Notifications & Privacy'),
                  _IosGroupedCard(
                    rows: [
                      IosRow(
                        icon: Icons.notifications_active_rounded,
                        iconColor: const Color(0xFFFF3B30),
                        label: 'Notifications',
                        sublabel: 'Push, Email, SMS',
                        trailing: IosTrailing.none,
                        onTap: () => _showNotifications(context, ref, auth),
                      ),
                      IosRow(
                        icon: Icons.shield_rounded,
                        iconColor: const Color(0xFFFF9500),
                        label: 'Two-Factor Authentication',
                        trailing: IosTrailing.switch_,
                        onTap: () => _toggle2FA(context, ref, auth),
                      ),
                      IosRow(
                        icon: Icons.devices_rounded,
                        iconColor: const Color(0xFF8E8E93),
                        label: 'Active Sessions',
                        value: '2 devices',
                        trailing: IosTrailing.none,
                        onTap: () => _showSessions(context),
                      ),
                      IosRow(
                        icon: Icons.fingerprint_rounded,
                        iconColor: const Color(0xFF34C759),
                        label: 'Face ID & Passcode',
                        trailing: IosTrailing.none,
                        onTap: () => _showBiometric(context),
                      ),
                    ],
                  ),
                  _section(context, 'Appearance'),
                  _IosGroupedCard(
                    rows: [
                      IosRow(
                        icon: themeMode == AppThemeMode.dark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        iconColor: const Color(0xFF8E8E93),
                        label: 'Appearance',
                        sublabel:
                            'Following: ${_label(themeMode)}',
                        trailing: IosTrailing.none,
                        onTap: () => _showAppearance(context, ref, themeMode),
                      ),
                      IosRow(
                        icon: Icons.palette_rounded,
                        iconColor: const Color(0xFFFF2D55),
                        label: 'Accent Color',
                        value: 'Red',
                        trailing: IosTrailing.none,
                        onTap: () => _showAccent(context),
                      ),
                    ],
                  ),
                  _section(context, 'General'),
                  _IosGroupedCard(
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
                          await ref
                              .read(authControllerProvider.notifier)
                              .signOut();
                          if (context.mounted) context.go(AppRoutes.home);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Text('ShipNow v1.0.0',
                            style: TextStyle(
                                fontSize: 12,
                                color: context.textMutedColor)),
                        const SizedBox(height: 4),
                        Text('Built by Mavis · ${DateTime.now().year}',
                            style: TextStyle(
                                fontSize: 10,
                                color: context.textSubtleColor)),
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
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
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

class _IosGroupedCard extends StatelessWidget {
  final List<Widget> rows;
  const _IosGroupedCard({required this.rows});
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
            if (i < rows.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Container(
                  height: 0.4,
                  color: context.dividerColor,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String company;
  const _ProfileHeader(
      {required this.name, required this.email, required this.company});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brandGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.30),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 30),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(name,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: context.textColor,
                    letterSpacing: -0.4)),
            const SizedBox(height: 2),
            Text(email,
                style: TextStyle(
                    fontSize: 13, color: context.textMutedColor)),
            if (company.isNotEmpty)
              Text(company,
                  style: TextStyle(
                      fontSize: 12, color: context.textSubtleColor)),
          ],
        ),
      ),
    );
  }
}

// ── Modals (kept compact) ────────────────────────────────────────────
void _showAddCard(BuildContext context) => showIosSheet(
      context: context,
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('Add payment method',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.textColor)),
          const SizedBox(height: 12),
          IosTextField(controller: TextEditingController(), label: 'Card number'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: IosTextField(controller: TextEditingController(), label: 'MM/YY')),
            const SizedBox(width: 10),
            Expanded(child: IosTextField(controller: TextEditingController(), label: 'CVC')),
          ]),
          const SizedBox(height: 16),
          IosPrimaryButton(
              label: 'Save card',
              icon: Icons.check_rounded,
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Card saved (mock)')));
              }),
        ],
      ),
    );

void _showCurrencies(BuildContext context) {
  showIosSheet(
    context: context,
    child: ListView(
      shrinkWrap: true,
      children: [
        Text('Default currency',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.textColor)),
        const SizedBox(height: 12),
        ...kFiatCurrencies.map((c) => IosRow(
              icon: Icons.public_rounded,
              iconColor: const Color(0xFF5856D6),
              label: '${c.flag}  ${c.name}',
              sublabel: c.code,
              trailing: IosTrailing.none,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Default set to ${c.code}')));
              },
            )),
      ],
    ),
  );
}

void _showLanguages(BuildContext context) {
  showIosSheet(
    context: context,
    child: ListView(
      shrinkWrap: true,
      children: const [
        '🇺🇸  English (US)',
        '🇬🇧  English (UK)',
        '🇲🇾  Bahasa Melayu',
        '🇨🇳  中文 (简体)',
        '🇯🇵  日本語',
        '🇰🇷  한국어',
        '🇪🇸  Español',
        '🇫🇷  Français',
        '🇩🇪  Deutsch',
        '🇮🇳  हिन्दी',
        '🇹🇭  ไทย',
        '🇻🇳  Tiếng Việt',
        '🇸🇦  العربية',
        '🇧🇷  Português (BR)',
      ]
          .map((s) => IosRow(
                icon: Icons.language_rounded,
                iconColor: const Color(0xFF007AFF),
                label: s,
                trailing: IosTrailing.none,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Language: $s')));
                },
              ))
          .toList(),
    ),
  );
}

void _showNotifications(BuildContext context, WidgetRef ref, AuthState auth) =>
    showIosSheet(
      context: context,
      child: StatefulBuilder(builder: (ctx, setS) {
        var push = true, email = true, sms = false;
        return ListView(
          shrinkWrap: true,
          children: [
            Text('Notifications',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.textColor)),
            const SizedBox(height: 12),
            IosRow(
              icon: Icons.notifications_active_rounded,
              iconColor: const Color(0xFFFF3B30),
              label: 'Push notifications',
              trailing: IosTrailing.none,
              customTrailing: Switch.adaptive(value: push, onChanged: (v) {}),
            ),
            IosRow(
              icon: Icons.email_rounded,
              iconColor: const Color(0xFF007AFF),
              label: 'Email',
              trailing: IosTrailing.none,
              customTrailing: Switch.adaptive(value: email, onChanged: (v) {}),
            ),
            IosRow(
              icon: Icons.sms_rounded,
              iconColor: const Color(0xFF34C759),
              label: 'SMS',
              trailing: IosTrailing.none,
              customTrailing: Switch.adaptive(value: sms, onChanged: (v) {}),
            ),
          ],
        );
      }),
    );

void _toggle2FA(BuildContext context, WidgetRef ref, AuthState auth) async {
  final p = auth.profile;
  if (p != null) {
    await ref
        .read(authControllerProvider.notifier)
        .updateProfile(p.copyWith(twoFactorEnabled: !p.twoFactorEnabled));
  }
}

void _showSessions(BuildContext context) => showIosSheet(
      context: context,
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('Active sessions',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.textColor)),
          const SizedBox(height: 8),
          const IosRow(
            icon: Icons.phone_iphone_rounded,
            iconColor: Color(0xFF007AFF),
            label: 'iPhone 17 Pro Max · Singapore',
            sublabel: 'This device · 5 min ago',
            trailing: IosTrailing.checkmark,
          ),
          const IosRow(
            icon: Icons.laptop_mac_rounded,
            iconColor: Color(0xFF8E8E93),
            label: 'MacBook Pro · Kuala Lumpur',
            sublabel: '2 hours ago',
            trailing: IosTrailing.none,
          ),
        ],
      ),
    );

void _showBiometric(BuildContext context) => showIosSheet(
      context: context,
      child: ListView(
        shrinkWrap: true,
        children: const [
          IosRow(
            icon: Icons.face_rounded,
            iconColor: Color(0xFF34C759),
            label: 'Face ID',
            sublabel: 'Unlock the app and authorise payments',
            trailing: IosTrailing.switch_,
          ),
          IosRow(
            icon: Icons.fingerprint_rounded,
            iconColor: Color(0xFF8E8E93),
            label: 'Touch ID',
            sublabel: 'Used on supported iPads',
            trailing: IosTrailing.none,
          ),
        ],
      ),
    );

void _showAppearance(
    BuildContext context, WidgetRef ref, AppThemeMode current) {
  showIosSheet(
    context: context,
    child: ListView(
      shrinkWrap: true,
      children: [
        Text('Appearance',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.textColor)),
        const SizedBox(height: 12),
        for (final m in AppThemeMode.values)
          IosRow(
            icon: m == AppThemeMode.dark
                ? Icons.dark_mode_rounded
                : m == AppThemeMode.light
                    ? Icons.light_mode_rounded
                    : Icons.brightness_auto_rounded,
            iconColor: const Color(0xFF8E8E93),
            label: switch (m) {
              AppThemeMode.system => 'Follow system',
              AppThemeMode.light => 'Light',
              AppThemeMode.dark => 'Dark',
            },
            sublabel: switch (m) {
              AppThemeMode.system => 'Match iOS appearance',
              AppThemeMode.light => 'Always light',
              AppThemeMode.dark => 'Always dark',
            },
            trailing: m == current ? IosTrailing.checkmark : IosTrailing.none,
            onTap: () {
              ref.read(themeControllerProvider.notifier).set(m);
              Navigator.pop(context);
            },
          ),
      ],
    ),
  );
}

void _showAccent(BuildContext context) {
  final swatches = [
    ('Red', AppColors.brand),
    ('Orange', const Color(0xFFFF9500)),
    ('Yellow', const Color(0xFFFFCC00)),
    ('Green', const Color(0xFF34C759)),
    ('Indigo', const Color(0xFF5856D6)),
    ('Pink', const Color(0xFFFF2D55)),
  ];
  showIosSheet(
    context: context,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Accent color',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.textColor)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: swatches
              .map((s) => PressScale(
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Accent: ${s.$1}')));
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: s.$2,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: context.surfaceColor, width: 4),
                        boxShadow: AppElevation.xs,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    ),
  );
}

void _showAbout(BuildContext context) => showIosSheet(
      context: context,
      child: ListView(
        shrinkWrap: true,
        children: const [
          IosRow(
              icon: Icons.qr_code_2_rounded,
              iconColor: AppColors.brand,
              label: 'App version',
              sublabel: 'ShipNow 1.0.0 (build 1001)',
              trailing: IosTrailing.none),
          IosRow(
              icon: Icons.flash_on_rounded,
              iconColor: Color(0xFFFF9500),
              label: 'Backend status',
              sublabel: 'All systems operational',
              trailing: IosTrailing.none),
          IosRow(
              icon: Icons.shield_rounded,
              iconColor: Color(0xFF34C759),
              label: 'Security',
              sublabel: 'TLS 1.3 · Audit log · Rate limited',
              trailing: IosTrailing.none),
        ],
      ),
    );

void _showCarriers(BuildContext context) {
  showIosSheet(
    context: context,
    child: ListView(
      shrinkWrap: true,
      children: const [
        IosRow(
            icon: Icons.flight_takeoff_rounded,
            iconColor: Color(0xFFFFCC00),
            label: 'DHL Express',
            sublabel: '2–5 day global express · preferred',
            trailing: IosTrailing.checkmark),
        IosRow(
            icon: Icons.flight_takeoff_rounded,
            iconColor: Color(0xFFFFCC00),
            label: 'DHL',
            sublabel: '2–5 day express',
            trailing: IosTrailing.none),
        IosRow(
            icon: Icons.bolt_rounded,
            iconColor: Color(0xFF4D148C),
            label: 'FedEx',
            sublabel: '2–5 day express',
            trailing: IosTrailing.none),
        IosRow(
            icon: Icons.inventory_2_rounded,
            iconColor: Color(0xFF351C15),
            label: 'UPS',
            sublabel: '3–6 day standard',
            trailing: IosTrailing.none),
        IosRow(
            icon: Icons.departure_board_rounded,
            iconColor: Color(0xFFE60012),
            label: 'J&T Express',
            sublabel: '2–5 day ASEAN',
            trailing: IosTrailing.none),
      ],
    ),
  );
}

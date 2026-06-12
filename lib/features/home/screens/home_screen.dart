import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/design_system.dart';
import '../../../app/router.dart';
import '../../../core/models/carrier.dart';
import '../../../core/widgets/airpak_brand.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/carrier_logo.dart';
import '../../../core/widgets/motion.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _trackingController = TextEditingController();

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(onMenu: () => _showMenu(context))),
            SliverToBoxAdapter(child: _Hero(ctrl: _trackingController)),
            SliverToBoxAdapter(child: _QuickActions()),
            SliverToBoxAdapter(child: _TrackingInput(ctrl: _trackingController)),
            SliverToBoxAdapter(child: _CarrierStrip()),
            SliverToBoxAdapter(child: _Services()),
            SliverToBoxAdapter(child: _Stats()),
            SliverToBoxAdapter(child: _CTAs()),
            SliverToBoxAdapter(child: _Footer()),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ── Top app bar ──────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onMenu;
  const _Header({required this.onMenu});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AirpakHeaderLogo(markSize: 36, textSize: 22),
                Text('Global logistics platform',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.textMutedColor,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3)),
              ],
            ),
          ),
          _HeaderIcon(icon: Icons.notifications_none_rounded, onTap: () {}),
          _HeaderIcon(icon: Icons.menu_rounded, onTap: onMenu),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIcon({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: context.textColor),
        ),
      ),
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final TextEditingController ctrl;
  const _Hero({required this.ctrl});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFF7F1D1D)],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.30),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative glow circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'FAST & RELIABLE',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Ship anywhere.\nTrack everywhere.',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Door-to-door express, air & sea freight with real-time tracking across 220+ destinations.',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _HeroButton(
                      label: 'Track a parcel',
                      icon: Icons.qr_code_scanner_rounded,
                      filled: true,
                      onTap: () => context.push(AppRoutes.tracking),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroButton(
                      label: 'Sign in',
                      icon: Icons.login_rounded,
                      filled: false,
                      onTap: () => context.push(AppRoutes.welcome),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0);
  }
}

class _HeroButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _HeroButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: filled
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: filled ? AppColors.brand : Colors.white),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: filled ? AppColors.brand : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick actions ───────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final _actions = const [
    (Icons.add_box_outlined, 'Create', AppRoutes.portalCreate),
    (Icons.inventory_2_outlined, 'My\nshipments', AppRoutes.portalShipments),
    (Icons.map_outlined, 'Live\ntracking', AppRoutes.tracking),
    (Icons.support_agent_rounded, 'Get\nsupport', AppRoutes.portalSupport),
  ];
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Row(
        children: [
          for (var i = 0; i < _actions.length; i++) ...[
            Expanded(
              child: _QuickAction(
                icon: _actions[i].$1,
                label: _actions[i].$2,
                onTap: () => context.push(_actions[i].$3),
              ),
            ),
            if (i < _actions.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      radius: AppRadius.md,
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: context.textColor),
          ),
        ],
      ),
    );
  }
}

// ── Tracking input ──────────────────────────────────────────────────

class _TrackingInput extends StatelessWidget {
  final TextEditingController ctrl;
  const _TrackingInput({required this.ctrl});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpace.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.search_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Track a shipment',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text('LIVE',
                      style: TextStyle(
                          color: AppColors.brandDark,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Enter a tracking number to see live status, route, and ETA.',
              style: TextStyle(color: context.textMutedColor, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'APK…',
                prefixIcon: Icon(Icons.qr_code_rounded),
              ),
            ),
            const SizedBox(height: 12),
            AppPrimaryButton(
              label: 'Track now',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                final t = ctrl.text.trim();
                if (t.isEmpty) return;
                context.push('${AppRoutes.tracking}/$t');
              },
            ),
            const SizedBox(height: 10),
            AppSecondaryButton(
              label: 'Open full live map',
              icon: Icons.public_rounded,
              onPressed: () {
                context.push('${AppRoutes.liveMap}?tracking=APK2026052600003');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Services ────────────────────────────────────────────────────────

class _Services extends StatelessWidget {
  final _services = const [
    (Icons.bolt_rounded, 'Express', '1–4 day door-to-door delivery worldwide', 'From \$18', AppColors.brand, '4hr avg'),
    (Icons.flight_rounded, 'Air Freight', 'Time-critical cargo with priority handling', 'From \$75', AppColors.info, '1–2 days'),
    (Icons.directions_boat_rounded, 'Sea Freight', 'Cost-effective FCL & LCL for big shipments', 'From \$32', AppColors.gold, '22 days'),
    (Icons.shopping_bag_rounded, 'E-commerce', 'End-to-end fulfilment, returns & COD', 'Custom', AppColors.success, 'Flexible'),
  ];
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Our services'),
          const SizedBox(height: 8),
          ..._services.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ServiceRow(
                  icon: s.$1,
                  title: s.$2,
                  subtitle: s.$3,
                  price: s.$4,
                  color: s.$5,
                  badge: s.$6,
                ),
              )),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final Color color;
  final String badge;
  const _ServiceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.color,
    required this.badge,
  });
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: AppRadius.md,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(badge,
                          style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: context.textMutedColor, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(price,
              style: TextStyle(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Stats card ──────────────────────────────────────────────────────

class _Stats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: AppCard(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
        ),
        radius: AppRadius.xl,
        padding: const EdgeInsets.all(AppSpace.xxl),
        border: null,
        shadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.insights_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('Why AirPak',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.bolt_rounded, color: AppColors.success, size: 12),
                      SizedBox(width: 4),
                      Text('+12% YoY',
                          style: TextStyle(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('Logistics for every scale',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4)),
            const SizedBox(height: 4),
            Text('From single parcels to enterprise fleets.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13)),
            const SizedBox(height: 18),
            Row(
              children: const [
                Expanded(child: _StatPill(value: '220+', label: 'Destinations')),
                SizedBox(width: 8),
                Expanded(child: _StatPill(value: '99.8%', label: 'On-time')),
                SizedBox(width: 8),
                Expanded(child: _StatPill(value: '2.4M', label: 'Parcels / yr')),
                SizedBox(width: 8),
                Expanded(child: _StatPill(value: '24/7', label: 'Support')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  const _StatPill({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              )),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

// ── CTAs (enterprise + customs) ─────────────────────────────────────

class _CTAs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _CTACard(
              icon: Icons.business_rounded,
              title: 'Enterprise',
              subtitle: 'Onboard your business in days, not weeks.',
              color: AppColors.brand,
              cta: 'Get started',
              onTap: () => context.push(AppRoutes.onboarding),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _CTACard(
              icon: Icons.shield_rounded,
              title: 'Customs & docs',
              subtitle: 'We handle the paperwork, you ship.',
              color: AppColors.accent,
              cta: 'Learn more',
              onTap: () => context.push(AppRoutes.tracking),
            ),
          ),
        ],
      ),
    );
  }
}

class _CTACard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String cta;
  final Color color;
  final VoidCallback onTap;
  const _CTACard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      radius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  color: context.textMutedColor,
                  fontSize: 12,
                  height: 1.4)),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(cta,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, color: color, size: 14),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Footer ──────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandMark(size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AirpakWordmark(size: 18, showUnderline: false),
                    Text('support@airpak-express.com',
                        style: TextStyle(
                            color: context.textMutedColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _footerLink(context, 'Tracking', () => context.push(AppRoutes.tracking)),
              _footerLink(context, 'Sign in', () => context.push(AppRoutes.login)),
              _footerLink(context, 'Register', () => context.push(AppRoutes.register)),
              _footerLink(context, 'Enterprise', () => context.push(AppRoutes.onboarding)),
              _footerLink(context, 'Admin', () => context.push(AppRoutes.adminLogin)),
              _footerLink(context, 'Terms', () => context.push(AppRoutes.terms)),
              _footerLink(context, 'Privacy', () => context.push(AppRoutes.privacy)),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '© ${DateTime.now().year} AirPak Express. All rights reserved.',
              style: TextStyle(
                  color: AppColors.textSubtle, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── Menu bottom sheet ───────────────────────────────────────────────

class _MenuSheet extends StatelessWidget {
  final _items = const [
    (Icons.local_shipping_rounded, 'Track shipment', AppRoutes.tracking),
    (Icons.person_outline_rounded, 'Customer sign in', AppRoutes.login),
    (Icons.admin_panel_settings_rounded, 'Admin portal', AppRoutes.adminLogin),
    (Icons.business_rounded, 'Enterprise onboarding', AppRoutes.onboarding),
    (Icons.description_outlined, 'Terms', AppRoutes.terms),
    (Icons.privacy_tip_outlined, 'Privacy', AppRoutes.privacy),
  ];
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            for (final item in _items)
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(item.$1, color: AppColors.brand, size: 20),
                ),
                title: Text(item.$2,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: context.textMutedColor),
                onTap: () {
                  Navigator.pop(context);
                  context.push(item.$3);
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ── Carrier strip — worldwide carriers with motion ─────────────────
class _CarrierStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              children: [
                const SectionHeader('We ship with', padding: EdgeInsets.zero),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text('See all',
                      style: TextStyle(
                          color: AppColors.brand,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              itemCount: kWorldwideCarriers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final c = kWorldwideCarriers[i];
                return _CarrierTile(
                  carrier: c,
                  index: i,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CarrierTile extends StatefulWidget {
  final Carrier carrier;
  final int index;
  const _CarrierTile({required this.carrier, required this.index});
  @override
  State<_CarrierTile> createState() => _CarrierTileState();
}

class _CarrierTileState extends State<_CarrierTile> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final c = widget.carrier;
    return PressScale(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected carrier: ${c.name}')),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: MotionDurations.short,
          width: 86,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hover ? c.brandColor : context.borderColor,
              width: _hover ? 1.5 : 1,
            ),
            boxShadow: _hover ? context.cardShadow : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CarrierLogo(
                carrier: c,
                size: 40,
                borderRadius: BorderRadius.circular(10),
                selected: _hover,
                backgroundColor: c.logoAsset == null
                    ? null
                    : context.surfaceColor,
              ),
              const SizedBox(height: 6),
              Text(
                c.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: context.textColor,
                    letterSpacing: -0.1),
              ),
              const SizedBox(height: 1),
              Text(
                c.eta,
                style: TextStyle(
                    fontSize: 9.5,
                    color: context.textMutedColor,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

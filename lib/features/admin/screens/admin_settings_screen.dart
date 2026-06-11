import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_controller.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        const SectionHeader('Workspace'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, Color(0xFF111827)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AirPak Express',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    Text('admin@airpak-express.com',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: context.textMutedColor)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader('Security'),
        const SizedBox(height: 8),
        _row(context, Icons.shield_outlined, 'Two-factor auth', 'Enabled',
            AppColors.success),
        _row(context, Icons.devices, 'Active sessions', '2 devices'),
        _row(context, Icons.history, 'Audit log', 'Last 90 days'),
        const SizedBox(height: 16),
        const SectionHeader('Operations'),
        const SizedBox(height: 8),
        _row(context, Icons.local_shipping, 'Carrier integrations',
            'DHL, FedEx, UPS, Aramex'),
        _row(context, Icons.receipt_long, 'Invoice template', 'Default • v3'),
        _row(context, Icons.map, 'Coverage zones', '12 countries'),
        const SizedBox(height: 16),
        const SectionHeader('Workspace preferences'),
        const SizedBox(height: 8),
        _row(context, Icons.language, 'Default language', 'English (US)'),
        _row(context, Icons.payments, 'Default currency', 'USD'),
        _row(context, Icons.tune, 'Auto-assign agents', 'On'),
        const SizedBox(height: 16),
        const SectionHeader('Signed in as'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.brandLight,
                child: Text(
                  auth.profile?.displayName.substring(0, 1).toUpperCase() ??
                      'A',
                  style: const TextStyle(
                      color: AppColors.brand, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.profile?.displayName ?? 'Admin',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(auth.profile?.email ?? '',
                        style: TextStyle(
                            color: context.textMutedColor, fontSize: 12)),
                  ],
                ),
              ),
              const Text('ADMIN',
                  style: TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w800,
                      fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value,
      [Color? valueColor]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.brand, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: context.textMutedColor),
        ],
      ),
    );
  }
}

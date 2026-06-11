import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/models/profile.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _company = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(authControllerProvider).profile;
    if (p != null) {
      _name.text = p.fullName ?? '';
      _company.text = p.companyName;
      _phone.text = p.phone ?? '';
      _email.text = p.email;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final p = ref.read(authControllerProvider).profile;
    if (p == null) return;
    final updated = AppProfile(
      id: p.id,
      email: _email.text.trim(),
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      avatarUrl: p.avatarUrl,
      role: p.role,
      walletBalance: p.walletBalance,
      rewardPoints: p.rewardPoints,
      companyName: _company.text.trim(),
      defaultAddressId: p.defaultAddressId,
      twoFactorEnabled: p.twoFactorEnabled,
    );
    await ref.read(authControllerProvider.notifier).updateProfile(updated);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(authControllerProvider).profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal info'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.portalSettings),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.brandLight,
                    child: Text(
                      (_name.text.isNotEmpty
                              ? _name.text[0]
                              : 'U')
                          .toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w800,
                          fontSize: 28),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Avatar upload mocked')),
                      );
                    },
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Change photo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _field(_name, 'Full name', Icons.person_outline),
            _field(_company, 'Company', Icons.business_outlined),
            _field(_email, 'Email', Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            _field(_phone, 'Phone', Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            if (p != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: AppColors.brand, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Account role: ${p.role.name.toUpperCase()}',
                        style: const TextStyle(
                            color: AppColors.brandDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: 'Save changes',
              icon: Icons.check,
              onPressed: _save,
              busy: _busy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}

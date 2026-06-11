import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/data/repositories.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/shipment.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_controller.dart';

final _customersProvider = FutureProvider.autoDispose
    .family<RepoResult<List<AppProfile>>, void>((ref, _) async {
  final repo = ref.watch(shipmentRepoProvider);
  final res = await repo.listProfiles();
  if (res.data == null) return res;
  final list = res.data!.where((p) => p.role == UserRole.customer).toList();
  return RepoResult.ok(list);
});

class AdminShipmentCreateScreen extends ConsumerStatefulWidget {
  const AdminShipmentCreateScreen({super.key});
  @override
  ConsumerState<AdminShipmentCreateScreen> createState() =>
      _AdminShipmentCreateScreenState();
}

class _AdminShipmentCreateScreenState
    extends ConsumerState<AdminShipmentCreateScreen> {
  AppProfile? _customer;
  final _receiver = TextEditingController();
  final _city = TextEditingController(text: 'Singapore');
  final _country = TextEditingController(text: 'Singapore');
  final _weight = TextEditingController(text: '1.5');
  final _reference = TextEditingController();
  String _service = 'Express';
  bool _busy = false;

  @override
  void dispose() {
    _receiver.dispose();
    _city.dispose();
    _country.dispose();
    _weight.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a customer first')),
      );
      return;
    }
    setState(() => _busy = true);
    final origin = Address(
      name: _customer!.displayName,
      phone: _customer!.phone ?? '',
      line1: '12 Jalan Sultan',
      city: 'Kuala Lumpur',
      state: 'Wilayah Persekutuan',
      postalCode: '50000',
      country: 'Malaysia',
    );
    final dest = Address(
      name: _receiver.text.trim().isEmpty
          ? 'Recipient'
          : _receiver.text.trim(),
      phone: '+60 12-345 6789',
      line1: '88 Beach Road',
      city: _city.text.trim(),
      state: _city.text.trim(),
      postalCode: '50000',
      country: _country.text.trim(),
    );
    final pkg = Package(
      weightKg: double.tryParse(_weight.text) ?? 1.0,
      lengthCm: 20,
      widthCm: 15,
      heightCm: 10,
      pieces: 1,
      description: 'Admin-created shipment',
    );
    final res = await ref.read(shipmentRepoProvider).create(
          userId: _customer!.id,
          origin: origin,
          destination: dest,
          package: pkg,
          service: _service,
          reference: _reference.text.trim().isEmpty
              ? null
              : _reference.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.data != null) {
      context.go(AppRoutes.adminPortal);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Created ${res.data!.trackingNumber} for ${_customer!.displayName}')),
      );
    } else if (res.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${res.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_customersProvider(null));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create on behalf of customer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.adminPortal),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader('Customer'),
              const SizedBox(height: 8),
              async.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.brand)),
                error: (e, _) => ErrorStateView(error: e),
                data: (res) {
                  final list = res.data ?? [];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AppProfile>(
                        value: _customer,
                        isExpanded: true,
                        hint: const Text('Select customer'),
                        items: [
                          for (final c in list)
                            DropdownMenuItem(
                              value: c,
                              child: Text('${c.displayName} • ${c.email}'),
                            ),
                        ],
                        onChanged: (v) => setState(() => _customer = v),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              const SectionHeader('Service'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in const ['Express', 'Standard', 'Air Freight', 'Sea Freight'])
                    ChoiceChip(
                      label: Text(s),
                      selected: _service == s,
                      onSelected: (_) => setState(() => _service = s),
                      selectedColor: AppColors.brandLight,
                      labelStyle: TextStyle(
                        color: _service == s
                            ? AppColors.brandDark
                            : AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const SectionHeader('Recipient'),
              const SizedBox(height: 8),
              TextField(
                controller: _receiver,
                decoration: const InputDecoration(
                  labelText: 'Recipient name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _city,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _country,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _weight,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  prefixIcon: Icon(Icons.scale),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _reference,
                decoration: const InputDecoration(
                  labelText: 'Reference (optional)',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(
                label: 'Create shipment',
                icon: Icons.add,
                onPressed: _submit,
                busy: _busy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

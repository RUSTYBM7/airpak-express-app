import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/models/carrier.dart';
import '../../../core/models/shipment.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/carrier_logo.dart';
import '../../auth/providers/auth_controller.dart';

class CreateShipmentScreen extends ConsumerStatefulWidget {
  const CreateShipmentScreen({super.key});
  @override
  ConsumerState<CreateShipmentScreen> createState() =>
      _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends ConsumerState<CreateShipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;

  // step 1
  String _service = 'Express';
  String _carrierId = 'dhl';
  final _reference = TextEditingController();
  final _declaredValue = TextEditingController(text: '0');

  // step 2 — origin
  final _oName = TextEditingController(text: 'Your Name');
  final _oPhone = TextEditingController(text: '+60 12-345 6789');
  final _oLine1 = TextEditingController(text: '12 Jalan Sultan');
  final _oCity = TextEditingController(text: 'Kuala Lumpur');
  final _oState = TextEditingController(text: 'Wilayah Persekutuan');
  final _oPostal = TextEditingController(text: '50000');
  final _oCountry = TextEditingController(text: 'Malaysia');

  // step 3 — destination
  final _dName = TextEditingController();
  final _dPhone = TextEditingController();
  final _dLine1 = TextEditingController();
  final _dCity = TextEditingController();
  final _dState = TextEditingController();
  final _dPostal = TextEditingController();
  final _dCountry = TextEditingController(text: 'Singapore');

  // step 4 — package
  double _weight = 1.5;
  double _length = 20;
  double _width = 15;
  double _height = 10;
  int _pieces = 1;
  final _description = TextEditingController();

  bool _busy = false;

  @override
  void dispose() {
    for (final c in [
      _reference, _declaredValue,
      _oName, _oPhone, _oLine1, _oCity, _oState, _oPostal, _oCountry,
      _dName, _dPhone, _dLine1, _dCity, _dState, _dPostal, _dCountry,
      _description,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (!_validateAddress([_oName, _oPhone, _oLine1, _oCity, _oState, _oPostal, _oCountry])) return;
      setState(() => _step = 2);
    } else if (_step == 2) {
      if (!_validateAddress([_dName, _dPhone, _dLine1, _dCity, _dState, _dPostal, _dCountry])) return;
      setState(() => _step = 3);
    } else {
      _submit();
    }
  }

  bool _validateAddress(List<TextEditingController> ctrls) {
    for (final c in ctrls) {
      if (c.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please complete all address fields')),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final auth = ref.read(authControllerProvider);
    final origin = Address(
      name: _oName.text.trim(),
      phone: _oPhone.text.trim(),
      line1: _oLine1.text.trim(),
      city: _oCity.text.trim(),
      state: _oState.text.trim(),
      postalCode: _oPostal.text.trim(),
      country: _oCountry.text.trim(),
    );
    final dest = Address(
      name: _dName.text.trim(),
      phone: _dPhone.text.trim(),
      line1: _dLine1.text.trim(),
      city: _dCity.text.trim(),
      state: _dState.text.trim(),
      postalCode: _dPostal.text.trim(),
      country: _dCountry.text.trim(),
    );
    final pkg = Package(
      weightKg: _weight,
      lengthCm: _length,
      widthCm: _width,
      heightCm: _height,
      pieces: _pieces,
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
    );
    final res = await ref.read(shipmentRepoProvider).create(
          userId: auth.userId,
          origin: origin,
          destination: dest,
          package: pkg,
          service: _service,
          reference: _reference.text.trim().isEmpty
              ? null
              : _reference.text.trim(),
        );
    if (!mounted) return;
    final created = res.data;
    if (created == null) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${res.error}')),
      );
      return;
    }

    // Run the payment. In mock mode this just confirms a fake intent;
    // in live mode the user sees the Stripe sheet (card + FPX if
    // enabled in the Stripe dashboard).
    final payment = await PaymentService.instance.payForShipment(created);
    if (!mounted) return;
    setState(() => _busy = false);

    if (payment.success) {
      _showSuccess(created, payment);
    } else {
      _showPaymentFailed(created, payment.error ?? 'Unknown error');
    }
  }

  void _showPaymentFailed(Shipment s, String reason) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.brand),
            SizedBox(width: 8),
            Text('Payment not completed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reason, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text(
              'Your shipment ${s.trackingNumber} is saved as a draft. '
              'You can retry payment from My Shipments.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: context.textMutedColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.portalShipments);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(Shipment s, PaymentResult payment) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('Shipment created'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tracking number', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            CopyableText(
              s.trackingNumber,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text('Quoted price: ${s.priceFormatted}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('ETA: ${s.etaFormatted}',
                style: TextStyle(color: context.textMutedColor)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.portalShipments);
            },
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('${AppRoutes.portalShipments}/${s.id}');
            },
            child: const Text('View shipment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create shipment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.portalDashboard),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 4,
                  minHeight: 6,
                  backgroundColor: AppColors.brandLight,
                  valueColor: AlwaysStoppedAnimation(AppColors.brand),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _buildStep(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: AppSecondaryButton(
                          label: 'Back',
                          icon: Icons.arrow_back,
                          onPressed: _busy
                              ? null
                              : () => setState(() => _step--),
                        ),
                      ),
                    if (_step > 0) const Gap(12),
                    Expanded(
                      child: AppPrimaryButton(
                        label: _step == 3
                            ? 'Pay & create'
                            : 'Continue',
                        icon: _step == 3
                            ? Icons.lock
                            : Icons.arrow_forward,
                        busy: _busy,
                        onPressed: _next,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _stepService();
      case 1:
        return _stepAddress(
          title: 'Sender address',
          name: _oName,
          phone: _oPhone,
          line1: _oLine1,
          city: _oCity,
          state: _oState,
          postal: _oPostal,
          country: _oCountry,
        );
      case 2:
        return _stepAddress(
          title: 'Recipient address',
          name: _dName,
          phone: _dPhone,
          line1: _dLine1,
          city: _dCity,
          state: _dState,
          postal: _dPostal,
          country: _dCountry,
        );
      case 3:
      default:
        return _stepPackage();
    }
  }

  Widget _stepService() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Service & options'),
        const SizedBox(height: 12),
        ...['Express', 'Standard', 'Air Freight', 'Sea Freight'].map((s) {
          final selected = _service == s;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => setState(() => _service = s),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.brand : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(_iconFor(s), color: AppColors.brand),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          Text(_descFor(s),
                              style: TextStyle(
                                  color: context.textMutedColor, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle,
                          color: AppColors.brand),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        const Text('Preferred carrier',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 4),
        Text('Pick the carrier that handles your parcel. The cost may change accordingly.',
            style: TextStyle(color: context.textMutedColor, fontSize: 12)),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kWorldwideCarriers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = kWorldwideCarriers[i];
              final sel = _carrierId == c.id;
              return InkWell(
                onTap: () => setState(() => _carrierId = c.id),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 84,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? c.brandColor.withValues(alpha: 0.08) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? c.brandColor : AppColors.border,
                      width: sel ? 1.8 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CarrierLogo(
                        carrier: c,
                        size: 30,
                        borderRadius: BorderRadius.circular(8),
                        selected: sel,
                        backgroundColor:
                            c.logoAsset == null ? null : Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                      Text(c.eta,
                          style: TextStyle(fontSize: 9, color: context.textMutedColor)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _reference,
          decoration: const InputDecoration(
            labelText: 'Reference (optional)',
            prefixIcon: Icon(Icons.tag),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _declaredValue,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Declared value (USD)',
            prefixIcon: Icon(Icons.attach_money),
          ),
        ),
      ],
    );
  }

  Widget _stepAddress({
    required String title,
    required TextEditingController name,
    required TextEditingController phone,
    required TextEditingController line1,
    required TextEditingController city,
    required TextEditingController state,
    required TextEditingController postal,
    required TextEditingController country,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        const SizedBox(height: 12),
        _tf(name, 'Full name', Icons.person_outline),
        _tf(phone, 'Phone', Icons.phone_outlined, keyboardType: TextInputType.phone),
        _tf(line1, 'Address line 1', Icons.home_outlined),
        Row(
          children: [
            Expanded(child: _tf(city, 'City', Icons.location_city)),
            const SizedBox(width: 10),
            Expanded(child: _tf(state, 'State', Icons.map_outlined)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _tf(postal, 'Postal code', Icons.markunread_mailbox_outlined)),
            const SizedBox(width: 10),
            Expanded(child: _tf(country, 'Country', Icons.flag_outlined)),
          ],
        ),
      ],
    );
  }

  Widget _stepPackage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Package details'),
        const SizedBox(height: 12),
        Text('Weight: ${_weight.toStringAsFixed(1)} kg',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        Slider(
          value: _weight,
          min: 0.1,
          max: 30,
          divisions: 299,
          activeColor: AppColors.brand,
          label: '${_weight.toStringAsFixed(1)} kg',
          onChanged: (v) => setState(() => _weight = v),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _dim('L (cm)', _length, (v) => setState(() => _length = v)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dim('W (cm)', _width, (v) => setState(() => _width = v)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dim('H (cm)', _height, (v) => setState(() => _height = v)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Pieces:', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton.outlined(
              onPressed: _pieces > 1
                  ? () => setState(() => _pieces--)
                  : null,
              icon: const Icon(Icons.remove),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('$_pieces',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            IconButton.outlined(
              onPressed: _pieces < 20
                  ? () => setState(() => _pieces++)
                  : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _description,
          decoration: const InputDecoration(
            labelText: 'Contents description (optional)',
            prefixIcon: Icon(Icons.notes),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.brandLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.brand),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Estimated total: ${_estimatedPrice()}',
                  style: TextStyle(
                      color: AppColors.brandDark,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dim(String label, double v, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: context.textMutedColor, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<double>(
              value: v,
              isExpanded: true,
              items: [
                for (var i = 5; i <= 100; i += 5)
                  DropdownMenuItem(value: i.toDouble(), child: Text('$i')),
              ],
              onChanged: (nv) => nv == null ? null : onChanged(nv),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tf(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  IconData _iconFor(String s) {
    switch (s) {
      case 'Express':
        return Icons.bolt;
      case 'Air Freight':
        return Icons.flight;
      case 'Sea Freight':
        return Icons.directions_boat;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  String _descFor(String s) {
    switch (s) {
      case 'Express':
        return '1–4 day door-to-door';
      case 'Standard':
        return 'Affordable 4–8 day delivery';
      case 'Air Freight':
        return 'Priority air cargo, 100kg+';
      case 'Sea Freight':
        return 'FCL / LCL, 22 day transit';
      default:
        return '';
    }
  }

  String _estimatedPrice() {
    final base = switch (_service) {
      'Express' => 18.0,
      'Standard' => 9.5,
      'Air Freight' => 75.0,
      'Sea Freight' => 32.0,
      _ => 12.0,
    };
    final w = _weight * 1.4;
    final size = (_length * _width * _height) / 5000;
    final intl = _oCountry.text.trim().toLowerCase() ==
            _dCountry.text.trim().toLowerCase()
        ? 1.0
        : 1.6;
    final total = base + w + size * intl;
    return '\$${total.toStringAsFixed(2)}';
  }
}

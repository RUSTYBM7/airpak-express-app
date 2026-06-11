import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/design_system.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_widgets.dart';

class EnterpriseOnboardingScreen extends StatefulWidget {
  const EnterpriseOnboardingScreen({super.key});
  @override
  State<EnterpriseOnboardingScreen> createState() =>
      _EnterpriseOnboardingScreenState();
}

class _EnterpriseOnboardingScreenState
    extends State<EnterpriseOnboardingScreen> {
  final PageController _page = PageController();
  int _step = 0;

  static const _steps = [
    (
      icon: Icons.business,
      title: 'Tell us about your business',
      subtitle:
          'We need a few details to set up your enterprise account and assign a dedicated success manager.',
      fields: ['Company name', 'Industry', 'Registration number', 'Tax ID'],
    ),
    (
      icon: Icons.local_shipping,
      title: 'What do you ship?',
      subtitle:
          'We will pre-configure carrier integrations, customs templates, and labelling rules.',
      fields: [
        'Primary service (Express / Standard / Sea / Air)',
        'Monthly volume',
        'Average parcel weight',
        'Top destination countries',
      ],
    ),
    (
      icon: Icons.tune,
      title: 'Integrations & automations',
      subtitle:
          'Connect your store, ERP, or marketplace. We support Shopify, WooCommerce, Lazada, Shopee and more.',
      fields: ['Platforms', 'API access (Y/N)', 'Webhook URL', 'Notes'],
    ),
    (
      icon: Icons.verified,
      title: 'Review & submit',
      subtitle:
          'Our team will reach out within one business day to finalise pricing, contracts and onboarding.',
      fields: [],
    ),
  ];

  final _companyName = TextEditingController();
  final _industry = TextEditingController();
  final _regNo = TextEditingController();
  final _taxId = TextEditingController();
  final _service = TextEditingController();
  final _volume = TextEditingController();
  final _weight = TextEditingController();
  final _countries = TextEditingController();
  final _platforms = TextEditingController();
  final _apiAccess = TextEditingController();
  final _webhook = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _page.dispose();
    for (final c in [
      _companyName, _industry, _regNo, _taxId, _service, _volume, _weight,
      _countries, _platforms, _apiAccess, _webhook, _notes
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
      _page.animateToPage(_step,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _submit();
    }
  }

  void _prev() {
    if (_step == 0) {
      context.pop();
      return;
    }
    setState(() => _step--);
    _page.animateToPage(_step,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _submit() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Application submitted'),
        content: const Text(
            'Thanks! Our enterprise team will reach out within 1 business day to finalise your account.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.home);
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _prev,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text('Enterprise onboarding · ${_step + 1}/${_steps.length}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: LinearProgressIndicator(
                value: (_step + 1) / _steps.length,
                minHeight: 6,
                backgroundColor: AppColors.brandLight,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.brand),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                onPageChanged: (i) => setState(() => _step = i),
                itemCount: _steps.length,
                itemBuilder: (_, i) => _buildStep(_steps[i], i),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: AppSecondaryButton(
                        label: 'Back',
                        icon: Icons.arrow_back,
                        onPressed: _prev,
                      ),
                    ),
                  if (_step > 0) const Gap(12),
                  Expanded(
                    child: AppPrimaryButton(
                      label: _step == _steps.length - 1
                          ? 'Submit application'
                          : 'Continue',
                      icon: _step == _steps.length - 1
                          ? Icons.check
                          : Icons.arrow_forward,
                      onPressed: _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(dynamic step, int i) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(step.icon, color: AppColors.brand, size: 28),
          ),
          const Gap(16),
          Text(step.title, style: Theme.of(context).textTheme.headlineSmall),
          const Gap(6),
          Text(step.subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.textMutedColor)),
          const Gap(20),
          ..._buildFields(i),
        ],
      ),
    );
  }

  List<Widget> _buildFields(int i) {
    final List<List<Widget>> fields = [
      [
        _tf(_companyName, 'Company name'),
        _tf(_industry, 'Industry'),
        _tf(_regNo, 'Registration number'),
        _tf(_taxId, 'Tax ID'),
      ],
      [
        _tf(_service, 'Primary service'),
        _tf(_volume, 'Monthly volume (parcels)'),
        _tf(_weight, 'Average parcel weight (kg)'),
        _tf(_countries, 'Top destination countries'),
      ],
      [
        _tf(_platforms, 'Platforms (Shopify, Lazada, etc.)'),
        _tf(_apiAccess, 'API access required (Y/N)'),
        _tf(_webhook, 'Webhook URL (optional)'),
        _tf(_notes, 'Anything else?'),
      ],
      [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.brandLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your application',
                  style: TextStyle(
                      color: AppColors.brandDark,
                      fontWeight: FontWeight.w800)),
              const Gap(8),
              _summary('Company', _companyName.text),
              _summary('Industry', _industry.text),
              _summary('Primary service', _service.text),
              _summary('Monthly volume', _volume.text),
              _summary('Platforms', _platforms.text),
            ],
          ),
        ),
      ],
    ];
    return fields[i];
  }

  Widget _tf(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.edit_outlined, size: 18),
        ),
      ),
    );
  }

  Widget _summary(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.brandDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                  color: AppColors.brandDark, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

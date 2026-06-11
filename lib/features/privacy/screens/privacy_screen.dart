import 'package:flutter/material.dart';

import '../../../app/design_system.dart';
import '../../../app/theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: _PrivacyBody(),
        ),
      ),
    );
  }
}

class _PrivacyBody extends StatelessWidget {
  const _PrivacyBody();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Privacy Policy', style: t.headlineSmall),
        const SizedBox(height: 6),
        Text('Last updated: January 2025',
            style: TextStyle(color: context.textMutedColor)),
        const SizedBox(height: 18),
        _section(context, '1. Information We Collect',
            'We collect personal information you provide when creating an account or booking a shipment, including name, email, phone, addresses, and payment information.'),
        _section(context, '2. How We Use Information',
            'We use your data to provide shipping services, process payments, send tracking updates, and improve our platform. We never sell your personal data.'),
        _section(context, '3. Cookies and Tracking',
            'We use cookies and similar technologies to keep you signed in, remember preferences, and measure platform performance. You can manage cookie preferences in your browser.'),
        _section(context, '4. Data Sharing',
            'We share shipment details with carriers, customs authorities, and payment processors strictly as needed to fulfil your shipment. We may also share data when required by law.'),
        _section(context, '5. Data Security',
            'Data is encrypted in transit (TLS) and at rest. Access to personal information is restricted to authorised personnel. Despite our efforts, no system is 100% secure.'),
        _section(context, '6. Your Rights',
            'You may access, correct, or delete your personal data at any time from your account settings. Contact support@airpak-express.com for further requests.'),
        _section(context, '7. International Transfers',
            'Data may be transferred to and processed in countries other than your own, including Singapore, where our servers are located.'),
        _section(context, '8. Updates to this Policy',
            'We may update this policy from time to time. Material changes will be communicated via email or in-app notice.'),
      ],
    );
  }

  Widget _section(BuildContext context, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}

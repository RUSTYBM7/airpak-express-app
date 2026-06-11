import 'package:flutter/material.dart';

import '../../../app/design_system.dart';
import '../../../app/theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: _TermsBody(),
        ),
      ),
    );
  }
}

class _TermsBody extends StatelessWidget {
  const _TermsBody();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Website Terms of Use', style: t.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Last updated: January 2025',
          style: TextStyle(color: context.textMutedColor),
        ),
        const SizedBox(height: 18),
        _section(context, '1. Acceptance of Terms',
            'The Website is designed to provide assistance to users ("User(s)", "you") in creating and managing shipments ("Shipment"). Your access to and use of the Website is subject to your acceptance of these Terms of Use and our Privacy Policy.'),
        _section(context, '2. Services',
            'ShipNow provides logistics software tools including shipment booking, label generation, tracking, and customer support. Services may be modified or discontinued at any time without prior notice.'),
        _section(context, '3. User Obligations',
            'You agree to provide accurate shipping information, comply with all applicable laws, and refrain from shipping prohibited items. You are responsible for any duties or taxes on cross-border shipments.'),
        _section(context, '4. Fees and Payment',
            'Fees are calculated based on weight, dimensions, destination, and selected service. Payment is due at the time of booking unless otherwise agreed in writing.'),
        _section(context, '5. Liability',
            'Our liability is limited to the declared value of the shipment or the standard carrier liability, whichever is lower. We are not liable for delays caused by force majeure, customs, or carrier events.'),
        _section(context, '6. Governing Law',
            'These Terms are governed by the laws of Singapore. Any dispute shall be resolved in the courts of Singapore.'),
        _section(context, '7. Contact',
            'For questions about these Terms, contact us at support@airpak-express.com.'),
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

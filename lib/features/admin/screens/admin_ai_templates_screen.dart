import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/cupertino.dart';
import '../../../app/design_system.dart';
import '../../../app/ios_components.dart';
import '../../../core/services/support_ai_service.dart';
import '../../../core/widgets/app_widgets.dart';

/// Admin AI Templates — generate marketing & ops content (banners,
/// social posts, documents, invoices) using the same backend that
/// powers the support assistant. Output is shown as a preview card
/// that the admin can copy, send, or schedule.
class AdminAiTemplatesScreen extends ConsumerStatefulWidget {
  const AdminAiTemplatesScreen({super.key});
  @override
  ConsumerState<AdminAiTemplatesScreen> createState() =>
      _AdminAiTemplatesScreenState();
}

class _AdminAiTemplatesScreenState extends ConsumerState<AdminAiTemplatesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _promptCtrl = TextEditingController();
  String? _output;
  bool _busy = false;
  String _selectedTone = 'Professional';
  String? _selectedTemplate;

  static const _templates = <_Template>[
    _Template(
      id: 'doc',
      label: 'Document',
      icon: Icons.description_rounded,
      color: AppColors.brand,
      blurb: 'Customs forms, commercial invoices, packing lists',
      starter: 'Draft a commercial invoice for an AirPak Express shipment of 12 cartons of cotton apparel, total value 12,400 USD, FOB Kuala Lumpur.',
    ),
    _Template(
      id: 'invoice',
      label: 'Invoice',
      icon: Icons.receipt_long_rounded,
      color: AppColors.success,
      blurb: 'Branded customer invoices with VAT/duty breakdown',
      starter: 'Create a customer-facing invoice for 1 express parcel, 4.2 kg, Kuala Lumpur to Singapore, service Express, total 49.80 USD.',
    ),
    _Template(
      id: 'banner',
      label: 'Banner',
      icon: Icons.image_rounded,
      color: AppColors.warning,
      blurb: 'Web hero banner copy for marketing pages',
      starter: 'Write hero copy for a 1200x400 web banner promoting AirPak Express air freight to Southeast Asia. 3 punchy variants, 8 words each.',
    ),
    _Template(
      id: 'social',
      label: 'Social post',
      icon: Icons.share_rounded,
      color: AppColors.info,
      blurb: 'Instagram, TikTok, X, LinkedIn posts with hashtags',
      starter: 'Write 4 social media posts (Instagram, TikTok, X, LinkedIn) for our new "Airpak Coin 1:1 USD" launch. Include hashtags.',
    ),
    _Template(
      id: 'email',
      label: 'Customer email',
      icon: Icons.mail_rounded,
      color: AppColors.accent,
      blurb: 'Transactional and marketing emails',
      starter: 'Write a hold-notification email for a customer whose parcel is held by customs in Singapore. Friendly, with a clear next step.',
    ),
    _Template(
      id: 'release',
      label: 'Press release',
      icon: Icons.campaign_rounded,
      color: AppColors.danger,
      blurb: 'Press release for product / partnership news',
      starter: 'Draft a 250-word press release announcing AirPak Express launching direct linehaul between Singapore, Kuala Lumpur, and Manila.',
    ),
  ];

  static const _tones = ['Professional', 'Friendly', 'Bold', 'Concise', 'Luxury'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _selectedTemplate = _templates.first.id;
  }

  @override
  void dispose() {
    _tabs.dispose();
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _output = null;
    });
    final tpl = _templates.firstWhere((t) => t.id == _selectedTemplate);
    final system = AiMessage(
      role: 'system',
      sentAt: DateTime.now(),
      content:
          'You are AirPak Express\'s marketing and operations copywriter. '
          'Write polished, production-ready ${tpl.label.toLowerCase()} copy. '
          'Tone: $_selectedTone. Output only the final copy — no preamble, no explanation.',
    );
    final user = AiMessage(
      role: 'user',
      sentAt: DateTime.now(),
      content: _promptCtrl.text.trim().isEmpty ? tpl.starter : _promptCtrl.text.trim(),
    );
    try {
      final svc = SupportAiService.instance;
      AiMessage reply;
      if (svc.isConfigured) {
        reply = await svc.chat(history: [system, user]);
      } else {
        // Local deterministic generator — gives the admin something
        // copy-ready even without a backend.
        reply = AiMessage(
          role: 'assistant',
          sentAt: DateTime.now(),
          content: _localGenerate(tpl.id, user.content, _selectedTone),
        );
      }
      setState(() => _output = reply.content);
      HapticService.success();
    } catch (e) {
      setState(() => _output = 'Failed to generate: $e');
      HapticService.error();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _localGenerate(String kind, String prompt, String tone) {
    final ts = DateFormat('MMM d, y').format(DateTime.now());
    switch (kind) {
      case 'invoice':
        return '''AIRPAK EXPRESS — COMMERCIAL INVOICE
Invoice no: INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}
Date: $ts

SHIPPER
AirPak Express (demo)
Kuala Lumpur, Malaysia

CONSIGNEE
Customer per shipment record

DESCRIPTION                       QTY   UNIT (USD)   AMOUNT (USD)
Express parcel — 4.2 kg             1      49.80          49.80
Fuel surcharge                      1       4.20           4.20
Insurance                          1       1.50           1.50
                                          ----------
                              Subtotal: USD 55.50
                              VAT (0%):  USD  0.00
                              Total:    USD 55.50

Payment terms: Due on receipt.
This invoice is generated by AirPak Express Operations.
''';
      case 'doc':
        return '''CUSTOMS / COMMERCIAL DOCUMENT
Document id: DOC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}
Issued: $ts

1. Description of goods: 12 cartons of cotton apparel.
2. HS code: 6109.10 — T-shirts, singlets, cotton, knit.
3. Country of origin: Malaysia.
4. Declared value: USD 12,400.00
5. Terms of delivery: FOB Kuala Lumpur.
6. Incoterms 2020.
7. Total weight: 86 kg. Total cartons: 12.
8. Marks & numbers: APK-EXPORT-001.

This document accompanies the shipment and is required by the receiving customs authority.
''';
      case 'banner':
        return '''VARIANT A — Speed
"Asia, in 24 hours."

VARIANT B — Trust
"Tracked. Insured. Settled in Airpak Coin."

VARIANT C — Premium
"From origin to doorstep, handled with care."''';
      case 'social':
        return '''INSTAGRAM (visual: Airpak Coin token over a parcel)
"New: pay shipping in Airpak Coin 🪙 1 APC = 1 USD, instant, no volatility. #AirPakExpress #AirpakCoin #CryptoShipping #Web3Logistics"

TIKTOK (15s vertical)
"POV: you ship a parcel, pay with Airpak Coin, and it's delivered before the video ends. Try APC at airpak-express.com 🚚💨 #ShipFaster #AirPak #LogisticsTok"

X (Twitter)
"Airpak Coin (APC) just went live on AirPak Express — settle shipping in a USD-pegged token. Fast. Predictable. Real. #AirPak #APC"

LINKEDIN
"Today AirPak Express launches Airpak Coin (APC), a 1:1 USD-pegged settlement token for cross-border shipping. Built for treasury teams that want predictable costs, exposed to a single FX-stable token, redeemable for shipping across 14 carriers and 220 destinations."''';
      case 'email':
        return '''Subject: Update on your AirPak Express parcel — held by customs

Hi {first_name},

We wanted to let you know that your parcel with tracking number {tracking} has been held by customs in Singapore. Our operations team has already filed the required paperwork and is working to clear it as quickly as possible.

What happens next:
1. Customs typically clears parcels within 24–48 hours when documents are complete.
2. If anything is needed from you, you'll receive a separate secure message.
3. We'll notify you the moment it's released and resumed for delivery.

Thank you for shipping with AirPak Express.

— AirPak Express Operations
''';
      case 'release':
        return '''FOR IMMEDIATE RELEASE — $ts

AirPak Express launches direct linehaul between Singapore, Kuala Lumpur, and Manila
Same-day acceptance, 24-hour linehaul, and 1:1 USD settlement in Airpak Coin.

SINGAPORE — AirPak Express today announced the launch of a direct linehaul network connecting Singapore, Kuala Lumpur, and Manila. The new service cuts typical cross-border transit times by 40 percent and is the first AirPak route to settle in Airpak Coin, the brand's 1:1 USD-pegged settlement token.

"We're building a logistics network that feels local in every country we serve," said AirPak Express's Head of Operations. "Direct linehaul plus a USD-stable settlement token means fewer surprises for our customers — predictable costs, predictable timing."

The service is now available to all AirPak Express customers in the three launch cities, with broader Southeast Asian expansion planned through the second half of the year.

About AirPak Express
AirPak Express is a global logistics platform routing shipments through 14 partner carriers across 220 destinations. The platform is built on an event-sourced architecture and offers real-time WebSocket tracking, Apple Intelligence support, and Airpak Coin (APC) settlement.

Media contact
press@airpak-express.com
''';
      default:
        return 'Generated draft for $kind. Tone: $tone. Prompt: $prompt';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        children: [
          // Tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                _Tab(label: 'Generator', icon: Icons.auto_awesome_rounded, active: true, onTap: () {}),
                const SizedBox(width: 8),
                _Tab(label: 'History', icon: Icons.history_rounded, active: false, onTap: () {
                  HapticService.selection();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recent generations will appear here.')),
                  );
                }),
              ],
            ),
          ),
          // Template grid
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Template type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.textMutedColor)),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.1,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _templates.map((t) {
                    final selected = t.id == _selectedTemplate;
                    return GestureDetector(
                      onTap: () {
                        HapticService.selection();
                        setState(() {
                          _selectedTemplate = t.id;
                          _promptCtrl.text = t.starter;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: selected ? t.color.withValues(alpha: 0.10) : context.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? t.color : context.borderColor, width: selected ? 2 : 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(t.icon, color: t.color, size: 20),
                            const SizedBox(height: 6),
                            Text(t.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: context.textColor)),
                            const SizedBox(height: 2),
                            Text(t.blurb,
                                textAlign: TextAlign.center,
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 9.5, color: context.textMutedColor, height: 1.2)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Tone picker
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tone', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.textMutedColor)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tones.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final t = _tones[i];
                      final selected = t == _selectedTone;
                      return GestureDetector(
                        onTap: () { HapticService.selection(); setState(() => _selectedTone = t); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.brand : context.surfaceColor,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: selected ? AppColors.brand : context.borderColor),
                          ),
                          child: Text(t, style: TextStyle(color: selected ? Colors.white : context.textColor, fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Prompt
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prompt', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.textMutedColor)),
                const SizedBox(height: 6),
                IosTextField(controller: _promptCtrl, hint: 'Describe what you need…', maxLines: 4, minLines: 3),
                const SizedBox(height: 12),
                IosPrimaryButton(
                  label: _busy ? 'Generating…' : 'Generate',
                  icon: _busy ? Icons.hourglass_top_rounded : Icons.auto_awesome_rounded,
                  onPressed: _busy ? null : _generate,
                ),
              ],
            ),
          ),
          // Output
          if (_output != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.brand.withValues(alpha: 0.4)),
                  boxShadow: context.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: AppColors.brand, size: 16),
                        const SizedBox(width: 6),
                        Text('Generated copy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.textColor)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            HapticService.success();
                            Clipboard.setData(ClipboardData(text: _output!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied to clipboard')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(8)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy_rounded, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('Copy', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: SelectableText(
                        _output!,
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 12.5,
                          height: 1.55,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Template {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final String blurb;
  final String starter;
  const _Template({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.blurb,
    required this.starter,
  });
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.icon, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.brand : context.surfaceColor,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: active ? AppColors.brand : context.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? Colors.white : context.textColor, size: 14),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: active ? Colors.white : context.textColor, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

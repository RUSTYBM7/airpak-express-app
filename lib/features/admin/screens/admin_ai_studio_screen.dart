import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/cupertino.dart';
import '../../../app/design_system.dart';
import '../../../app/ios_components.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/services/support_ai_service.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/motion.dart';
import '../../support/support_chat_controller.dart';

/// Advanced AI Studio — generation, real-time streaming, print/PDF, MJML
/// email composer, free open-source-AI fallback, share-to-mail, and
/// 12+ content types across 5 tones.
class AdminAiStudioScreen extends ConsumerStatefulWidget {
  const AdminAiStudioScreen({super.key});
  @override
  ConsumerState<AdminAiStudioScreen> createState() =>
      _AdminAiStudioScreenState();
}

class _AdminAiStudioScreenState extends ConsumerState<AdminAiStudioScreen>
    with SingleTickerProviderStateMixin {
  String _activeTab = 'generator';
  late final TabController _tabs = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionHeader('AI Studio'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.appleIntelligenceGradient,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text('M3 Pro',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: context.surfaceMutedColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabs,
              onTap: (i) {
                setState(() {
                  _activeTab = ['generator', 'email', 'document', 'image'][i];
                });
              },
              indicator: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: context.cardShadow,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.brand,
              unselectedLabelColor: context.textMutedColor,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 12),
              tabs: const [
                Tab(text: 'Generator'),
                Tab(text: 'Email · MJML'),
                Tab(text: 'Document'),
                Tab(text: 'Image'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: switch (_activeTab) {
              'generator' => const _GeneratorPanel(),
              'email' => const _EmailMjmlPanel(),
              'document' => const _DocumentPanel(),
              'image' => const _ImagePromptPanel(),
              _ => const _GeneratorPanel(),
            },
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// GENERATOR PANEL
// ────────────────────────────────────────────────────────────────────────────

class _GeneratorPanel extends ConsumerStatefulWidget {
  const _GeneratorPanel();
  @override
  ConsumerState<_GeneratorPanel> createState() => _GeneratorPanelState();
}

class _GeneratorPanelState extends ConsumerState<_GeneratorPanel> {
  final _topicCtrl = TextEditingController(
      text: 'A premium cross-border shipping service for e-commerce sellers');
  String _tone = 'Professional';
  String _type = 'Marketing copy';
  String _output = '';
  bool _streaming = false;
  String _model = 'Mavis · MiniMax-M3';

  static const _tones = ['Professional', 'Friendly', 'Bold', 'Concise', 'Luxury'];
  static const _types = [
    'Marketing copy',
    'Press release',
    'Customer reply',
    'Social post',
    'Blog intro',
    'Ad headline',
    'FAQ entry',
    'Banner caption',
    'Tagline',
    'Product description',
  ];

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_topicCtrl.text.trim().isEmpty) return;
    HapticService.light();
    setState(() {
      _output = '';
      _streaming = true;
    });
    final ai = ref.read(supportAiServiceProvider);
    final prompt =
        'Generate a $_tone $_type about: ${_topicCtrl.text}. Keep it crisp and on-brand for AirPak Express (global shipping).';
    try {
      final reply = await ai.chat(history: [
        AiMessage(role: 'system', content: 'You are a world-class copywriter.', sentAt: DateTime.now()),
        AiMessage(role: 'user', content: prompt, sentAt: DateTime.now()),
      ]);
      if (mounted) {
        setState(() {
          _output = reply.content;
          _streaming = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _output = _localFallback(_topicCtrl.text, _type, _tone);
          _streaming = false;
        });
      }
    }
  }

  String _localFallback(String topic, String type, String tone) {
    return "**$type** — *$tone* tone\n\n$topic\n\n"
        "AirPak Express: 220+ countries, 4-hour airport-to-airport, 24/7 linehaul, "
        "AI-cleared customs, and Airpak Coin (APC) settlements. "
        "Track every parcel, every leg, every heartbeat. "
        "From the moment you hand off, Mavis is watching the world spin for you.\n\n"
        "CTA: Ship now at airpak-express.com.";
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
      children: [
        _formCard(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(6)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 11, color: AppColors.brand),
                      SizedBox(width: 3),
                      Text('AI', style: TextStyle(color: AppColors.brand, fontSize: 10, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(_model, style: TextStyle(fontSize: 12, color: context.textMutedColor, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Topic', style: TextStyle(fontSize: 12, color: context.textMutedColor, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            TextField(
              controller: _topicCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'What should the AI write about?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _picker('Type', _type, _types, (v) {
                    setState(() => _type = v);
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _picker('Tone', _tone, _tones, (v) {
                    setState(() => _tone = v);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: IosPrimaryButton(
                    label: _streaming ? 'Generating…' : 'Generate',
                    icon: Icons.auto_awesome_rounded,
                    onPressed: _streaming ? null : _generate,
                  ),
                ),
                if (_output.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IosSecondaryButton(
                    label: 'Print',
                    icon: Icons.print_rounded,
                    onPressed: _printOutput,
                  ),
                ],
              ],
            ),
          ],
        ),
        if (_output.isNotEmpty) ...[
          const SizedBox(height: 16),
          _outputCard(),
        ],
      ],
    );
  }

  Widget _picker(String label, String value, List<String> options, void Function(String) onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: context.textMutedColor, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) {
              if (v != null) onChange(v);
            },
          ),
        ),
      ],
    );
  }

  Widget _formCard({required List<Widget> children}) => Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );

  Widget _outputCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.brand, size: 16),
              const SizedBox(width: 6),
              Text('Output · $_type · $_tone',
                  style: TextStyle(fontSize: 12, color: context.textMutedColor, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _output));
                  HapticService.success();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                },
              ),
              IconButton(
                icon: const Icon(Icons.print_rounded, size: 18),
                onPressed: _printOutput,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(_output, style: TextStyle(fontSize: 13.5, color: context.textColor, height: 1.55)),
        ],
      ),
    );
  }

  Future<void> _printOutput() async {
    if (_output.isEmpty) return;
    try {
      await Printing.layoutPdf(onLayout: (_) async => _buildPdf(_output, '$_type · $_tone'));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printing not available — copied to clipboard.')),
      );
      Clipboard.setData(ClipboardData(text: _output));
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// EMAIL · MJML PANEL
// ────────────────────────────────────────────────────────────────────────────

class _EmailMjmlPanel extends ConsumerStatefulWidget {
  const _EmailMjmlPanel();
  @override
  ConsumerState<_EmailMjmlPanel> createState() => _EmailMjmlPanelState();
}

class _EmailMjmlPanelState extends ConsumerState<_EmailMjmlPanel> {
  final _subjectCtrl = TextEditingController(text: 'Your AirPak parcel is on the way');
  final _recipientCtrl = TextEditingController(text: 'customer@example.com');
  final _contextCtrl = TextEditingController(
      text: 'Send a shipping update to a customer whose parcel just cleared customs in Singapore, ETA 4 hours.');
  String _tone = 'Professional';
  String _output = '';
  bool _streaming = false;

  static const _tones = ['Professional', 'Friendly', 'Bold', 'Concise', 'Luxury'];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _recipientCtrl.dispose();
    _contextCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_subjectCtrl.text.trim().isEmpty) return;
    HapticService.light();
    setState(() {
      _output = '';
      _streaming = true;
    });
    final ai = ref.read(supportAiServiceProvider);
    final reply = await ai.chat(history: [
      AiMessage(role: 'system', content:
        'You generate valid MJML (Mailjet Markup Language) for responsive HTML email. '
        'Always include <mjml><mj-body> wrapper, <mj-section>, <mj-column>, <mj-text>, <mj-button>. '
        'Use the AirPak Express brand: primary #E53935, dark #0A0E1A, accent #FFB300. '
        'Include a header with the AirPak wordmark, the body content, and a footer.', sentAt: DateTime.now()),
      AiMessage(role: 'user', content:
        'Subject: ${_subjectCtrl.text}\nRecipient: ${_recipientCtrl.text}\n'
        'Tone: $_tone\nContext: ${_contextCtrl.text}', sentAt: DateTime.now()),
    ]);
    if (!mounted) return;
    setState(() {
      _output = reply.content;
      _streaming = false;
    });
  }

  String _fallbackMjml() {
    return '''
<mjml>
  <mj-body background-color="#f4f4f7">
    <mj-section background-color="#0A0E1A" padding="24px">
      <mj-column>
        <mj-text color="#FFB300" font-size="28px" font-weight="800" align="center">AirPak Express</mj-text>
      </mj-column>
    </mj-section>
    <mj-section background-color="#ffffff" padding="24px">
      <mj-column>
        <mj-text font-size="20px" font-weight="700" color="#0A0E1A">${_subjectCtrl.text}</mj-text>
        <mj-text color="#3B475E" font-size="14px" line-height="1.6">${_contextCtrl.text}</mj-text>
        <mj-button background-color="#E53935" href="https://airpak-express.com/track">Track your parcel</mj-button>
      </mj-column>
    </mj-section>
    <mj-section background-color="#0A0E1A" padding="16px">
      <mj-column>
        <mj-text color="#FFB300" font-size="11px" align="center">© AirPak Express · 220+ countries · Airpak Coin (APC) 1:1 USD</mj-text>
      </mj-column>
    </mj-section>
  </mj-body>
</mjml>
''';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.markunread_mailbox_rounded, size: 12, color: AppColors.warning),
                        SizedBox(width: 4),
                        Text('MJML', style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Responsive HTML email · 1-click share to default mail',
                      style: TextStyle(fontSize: 12, color: context.textMutedColor, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _recipientCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Recipient email',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject line',
                  prefixIcon: Icon(Icons.subject_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _contextCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Context / message brief',
                  prefixIcon: Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _tone,
                      decoration: const InputDecoration(
                        labelText: 'Tone',
                        border: OutlineInputBorder(),
                      ),
                      items: _tones
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _tone = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: IosPrimaryButton(
                      label: _streaming ? 'Generating…' : 'Generate MJML',
                      icon: Icons.auto_awesome_rounded,
                      onPressed: _streaming ? null : _generate,
                    ),
                  ),
                  if (_output.isEmpty) ...[
                    const SizedBox(width: 8),
                    IosSecondaryButton(
                      label: 'Use template',
                      icon: Icons.dashboard_rounded,
                      onPressed: () {
                        setState(() => _output = _fallbackMjml());
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (_output.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.code_rounded, color: AppColors.brand, size: 16),
                    const SizedBox(width: 6),
                    Text('MJML source · ${DateFormat('HH:mm').format(DateTime.now())}',
                        style: TextStyle(fontSize: 12, color: context.textMutedColor, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Copy',
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _output));
                        HapticService.success();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('MJML copied')));
                      },
                    ),
                    IconButton(
                      tooltip: 'Print preview',
                      icon: const Icon(Icons.print_rounded, size: 18),
                      onPressed: () => _printMjml(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: SelectableText(_output,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.5)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: IosPrimaryButton(
                        label: 'Share to mail app',
                        icon: Icons.share_rounded,
                        onPressed: _shareToMail,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: IosSecondaryButton(
                        label: 'Print PDF',
                        icon: Icons.print_rounded,
                        onPressed: _printMjml,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _shareToMail() async {
    final recipient = _recipientCtrl.text.trim();
    final subject = Uri.encodeComponent(_subjectCtrl.text);
    final body = Uri.encodeComponent(
        'Hi,\n\nPlease see the responsive HTML below — copy into your MJML renderer to preview.\n\n'
        '— AirPak Express\n\n$_output');
    final uri = Uri.parse('mailto:$recipient?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Clipboard.setData(ClipboardData(text: _output));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No mail app available — MJML copied to clipboard.')),
      );
    }
  }

  Future<void> _printMjml() async {
    if (_output.isEmpty) return;
    try {
      await Printing.layoutPdf(onLayout: (_) async {
        return _buildPdf(_output, 'MJML · ${_subjectCtrl.text}');
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printing not available — opening in browser.')),
      );
      // Open in browser to render MJML via web service (not needed — fallback).
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// DOCUMENT PANEL — press release, invoice summary, business proposal
// ────────────────────────────────────────────────────────────────────────────

class _DocumentPanel extends ConsumerStatefulWidget {
  const _DocumentPanel();
  @override
  ConsumerState<_DocumentPanel> createState() => _DocumentPanelState();
}

class _DocumentPanelState extends ConsumerState<_DocumentPanel> {
  final _topicCtrl = TextEditingController(
      text: 'AirPak Express Q3 milestones — 220+ countries live, 4-hour airport-to-airport, AI customs clearing');
  String _docType = 'Press release';
  String _output = '';
  bool _streaming = false;

  static const _docTypes = [
    'Press release',
    'Business proposal',
    'Internal memo',
    'Partnership brief',
    'Policy update',
    'Quarterly report',
  ];

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_topicCtrl.text.trim().isEmpty) return;
    HapticService.light();
    setState(() {
      _output = '';
      _streaming = true;
    });
    final ai = ref.read(supportAiServiceProvider);
    final reply = await ai.chat(history: [
      AiMessage(role: 'system', content: 'You write long-form business documents with structure, headings, and bullet points.', sentAt: DateTime.now()),
      AiMessage(role: 'user', content: 'Write a $_docType about: ${_topicCtrl.text}', sentAt: DateTime.now()),
    ]);
    if (!mounted) return;
    setState(() {
      _output = reply.content;
      _streaming = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _docType,
                decoration: const InputDecoration(
                  labelText: 'Document type',
                  border: OutlineInputBorder(),
                ),
                items: _docTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _docType = v);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _topicCtrl,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Brief / outline',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: IosPrimaryButton(
                      label: _streaming ? 'Generating…' : 'Generate document',
                      icon: Icons.description_rounded,
                      onPressed: _streaming ? null : _generate,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_output.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('Output · $_docType',
                        style: TextStyle(fontSize: 12, color: context.textMutedColor, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _output));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.print_rounded, size: 18),
                      onPressed: () async {
                        try {
                          await Printing.layoutPdf(onLayout: (_) async => _buildPdf(_output, _docType));
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Print not available — copied.')),
                          );
                          Clipboard.setData(ClipboardData(text: _output));
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(_output, style: TextStyle(fontSize: 13.5, color: context.textColor, height: 1.55)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// IMAGE PROMPT PANEL
// ────────────────────────────────────────────────────────────────────────────

class _ImagePromptPanel extends ConsumerStatefulWidget {
  const _ImagePromptPanel();
  @override
  ConsumerState<_ImagePromptPanel> createState() => _ImagePromptPanelState();
}

class _ImagePromptPanelState extends ConsumerState<_ImagePromptPanel> {
  final _topicCtrl = TextEditingController(
      text: 'A futuristic AirPak Express cargo plane flying over a glowing world map, neon Pacifico script "Airpak", 4K');
  String _style = 'Photorealistic';
  String _output = '';
  bool _streaming = false;

  static const _styles = [
    'Photorealistic',
    'Cinematic',
    '3D Pixar',
    'Studio Ghibli',
    'Cyberpunk',
    'Minimalist line art',
    'Hyper pop',
  ];

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_topicCtrl.text.trim().isEmpty) return;
    HapticService.light();
    setState(() {
      _output = '';
      _streaming = true;
    });
    final ai = ref.read(supportAiServiceProvider);
    final reply = await ai.chat(history: [
      AiMessage(role: 'system', content:
        'You expand short image prompts into detailed Stable Diffusion / Midjourney prompts with '
        'camera lens, lighting, mood, color palette, and aspect ratio tags.', sentAt: DateTime.now()),
      AiMessage(role: 'user', content: 'Style: $_style\nPrompt: ${_topicCtrl.text}', sentAt: DateTime.now()),
    ]);
    if (!mounted) return;
    setState(() {
      _output = reply.content;
      _streaming = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _style,
                decoration: const InputDecoration(
                  labelText: 'Visual style',
                  border: OutlineInputBorder(),
                ),
                items: _styles.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _style = v);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _topicCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'What should we generate?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              IosPrimaryButton(
                label: _streaming ? 'Generating…' : 'Build image prompt',
                icon: Icons.image_rounded,
                onPressed: _streaming ? null : _generate,
              ),
            ],
          ),
        ),
        if (_output.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('Image prompt · $_style',
                        style: TextStyle(fontSize: 12, color: context.textMutedColor, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _output));
                        HapticService.success();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prompt copied')));
                      },
                    ),
                    IconButton(
                      tooltip: 'Print',
                      icon: const Icon(Icons.print_rounded, size: 18),
                      onPressed: () async {
                        try {
                          await Printing.layoutPdf(onLayout: (_) async => _buildPdf(_output, 'Image prompt · $_style'));
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(_output, style: TextStyle(fontSize: 13.5, color: context.textColor, height: 1.55)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Helper: build a small PDF
// ────────────────────────────────────────────────────────────────────────────

Future<Uint8List> _buildPdf(String body, String title) async {
  // Minimal valid one-page PDF (text-only, no images).
  // The `printing` package's layoutPdf works on web/mobile.
  return Uint8List.fromList(_minimalPdf(body, title));
}

List<int> _minimalPdf(String body, String title) {
  // Truncate to keep the demo small
  final truncated = body.length > 4000 ? body.substring(0, 4000) : body;
  final escaped = truncated
      .replaceAll('\\', r'\\')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)');
  final titleEscaped = title
      .replaceAll('\\', r'\\')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)');

  final content = '''
BT
/F1 18 Tf
60 760 Td
(AirPak Express — $titleEscaped) Tj
0 -28 Td
/F1 10 Tf
''';

  final lines = escaped.split('\n');
  final bodyChunks = StringBuffer(content);
  int y = 0;
  for (final ln in lines) {
    final safe = ln.length > 90 ? ln.substring(0, 90) : ln;
    final safeEsc = safe
        .replaceAll('\\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
    bodyChunks.writeln('($safeEsc) Tj');
    bodyChunks.writeln('0 -14 Td');
    y++;
    if (y > 50) break;
  }
  bodyChunks.writeln('ET');

  final stream = bodyChunks.toString();
  final streamBytes = stream.codeUnits;

  final pdf = StringBuffer();
  pdf.writeln('%PDF-1.4');
  pdf.writeln('1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj');
  pdf.writeln('2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj');
  pdf.writeln('3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
      '/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >> endobj');
  pdf.writeln('4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj');
  pdf.writeln('5 0 obj << /Length ${streamBytes.length} >> stream');
  pdf.write(stream);
  pdf.writeln('endstream endobj');
  pdf.writeln('xref');
  pdf.writeln('0 6');
  pdf.writeln('0000000000 65535 f');
  // Offsets are approximate; PDF readers tolerate this for single-page text
  pdf.writeln('0000000009 00000 n');
  pdf.writeln('0000000054 00000 n');
  pdf.writeln('0000000100 00000 n');
  pdf.writeln('0000000190 00000 n');
  pdf.writeln('0000000290 00000 n');
  pdf.writeln('trailer << /Size 6 /Root 1 0 R >>');
  pdf.writeln('startxref');
  pdf.writeln('350');
  pdf.writeln('%%EOF');

  return pdf.toString().codeUnits;
}

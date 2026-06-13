import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/cupertino.dart';
import '../../../app/design_system.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/motion.dart';

/// AI Studio — generation tools for marketing copy, customer replies,
/// document summarisation, and rate insights. The real backend hits
/// OpenAI/Anthropic; mock mode streams realistic demo responses.
class AdminAiStudioScreen extends ConsumerStatefulWidget {
  const AdminAiStudioScreen({super.key});
  @override
  ConsumerState<AdminAiStudioScreen> createState() =>
      _AdminAiStudioScreenState();
}

class _AdminAiStudioScreenState
    extends ConsumerState<AdminAiStudioScreen>
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
                  _activeTab = ['generator', 'analyzer', 'vision', 'voice'][i];
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
                Tab(text: 'Analyzer'),
                Tab(text: 'Vision'),
                Tab(text: 'Voice'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _activeTab == 'generator'
                ? _GeneratorTab()
                : _AnalyzerTab(),
          ),
        ],
      ),
    );
  }
}

class _GeneratorTab extends StatefulWidget {
  @override
  State<_GeneratorTab> createState() => _GeneratorTabState();
}

class _GeneratorTabState extends State<_GeneratorTab> {
  String _kind = 'Marketing email';
  final _input = TextEditingController(
      text: 'Launch promo: 20% off all Asia-Pacific shipments booked in June.');
  final _output = TextEditingController(
      text: '''Subject: ✈️ 20% off — your shipments across APAC, this June only

Hi {{first_name}},

Big news from AirPak Express: for the entire month of June, save 20% on
every Asia-Pacific shipment you book through us.

That means door-to-door express to Tokyo, Shanghai, Singapore, Seoul, and
220+ destinations — at our lowest rates of the year.

Why book with AirPak in June?
• \$0 fuel surcharge on all Pacific lanes
• Free AirPak Coin credit on every shipment (yes, real money)
• Priority customs handling — average 14 hours faster

Tap below to book in 30 seconds and lock in your discount.

[Book my shipment →]   (link auto-inserts customer code)

Cheers,
The AirPak team''');
  bool _generating = false;

  void _generate() {
    HapticService.medium();
    setState(() => _generating = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      setState(() => _generating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final kinds = const [
      'Marketing email',
      'Shipment description',
      'Customs declaration',
      'Customer reply',
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (final k in kinds)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(k, style: const TextStyle(fontSize: 11)),
                        selected: _kind == k,
                        onSelected: (_) => setState(() => _kind = k),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: TextField(
                    controller: _input,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(
                        color: context.textColor,
                        fontSize: 13,
                        height: 1.5),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText:
                          'Describe what you need. e.g. "Write a marketing email announcing 20% off June shipments"',
                      isCollapsed: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: AppPrimaryButton(
                  label: 'Generate',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: _generate,
                  busy: _generating,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppColors.brand, size: 16),
                  const SizedBox(width: 6),
                  Text('Generated output',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: context.textColor)),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      HapticService.light();
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticService.light();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _output.text,
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 13,
                          height: 1.5,
                          fontFamily: GoogleFonts.inter().fontFamily),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalyzerTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _AnCard(
          icon: Icons.trending_up_rounded,
          color: AppColors.success,
          title: 'Q2 revenue up 24%',
          body:
              'Carrier mix is tilting toward DHL (+8pts) and FedEx (+5pts). Recommend promotional AirPak Coin credits on Asia lane bookings.',
        ),
        _AnCard(
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
          title: '6 shipments at risk',
          body:
              'Detected delay signals on 4 Singapore→Europe parcels. Suggest switching to Aramex AirFreight priority queue.',
        ),
        _AnCard(
          icon: Icons.flag_rounded,
          color: AppColors.danger,
          title: 'Customs flags',
          body:
              '3 shipments need HS code review for Indonesia destination. Drafted custom reply in Customer replies queue.',
        ),
        _AnCard(
          icon: Icons.auto_graph_rounded,
          color: AppColors.info,
          title: 'Capacity forecast',
          body:
              'July bookings trending +12% over June. Lock 30% more slot with DHL Express for Q3 to keep 24h SLA.',
        ),
      ],
    );
  }
}

class _AnCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _AnCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.body});
  @override
  Widget build(BuildContext context) {
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
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Icon(Icons.arrow_outward_rounded,
                  color: context.textMutedColor, size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: context.textColor)),
          const SizedBox(height: 4),
          Expanded(
            child: Text(body,
                style: TextStyle(
                    fontSize: 11.5,
                    color: context.textMutedColor,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}

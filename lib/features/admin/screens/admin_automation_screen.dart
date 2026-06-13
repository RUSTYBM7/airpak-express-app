import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/cupertino.dart';
import '../../../app/design_system.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_widgets.dart';

/// Automation Rules — if-this-then-that style rule editor with carrier
/// routing, customer segments, and SLA escalations.
class AdminAutomationScreen extends ConsumerStatefulWidget {
  const AdminAutomationScreen({super.key});
  @override
  ConsumerState<AdminAutomationScreen> createState() =>
      _AdminAutomationScreenState();
}

class _AdminAutomationScreenState
    extends ConsumerState<AdminAutomationScreen> {
  final _rules = [
    {
      'name': 'Singapore → Europe: prefer DHL Express',
      'trigger': 'route = SG → EU',
      'action': 'auto-pick DHL when ETA < 48h',
      'enabled': true,
      'runs': 1284,
    },
    {
      'name': 'Repeat-customer discount',
      'trigger': 'customer orders > 5 / month',
      'action': 'auto-apply 10% AirPak Coin credit',
      'enabled': true,
      'runs': 412,
    },
    {
      'name': 'Customs flag escalation',
      'trigger': 'HS code missing or unclear',
      'action': 'route to CustomsAgent Bob + SMS customer',
      'enabled': true,
      'runs': 38,
    },
    {
      'name': 'Bulk upload discount',
      'trigger': 'CSV import > 10 shipments',
      'action': 'auto-apply 8% off and priority queue',
      'enabled': false,
      'runs': 0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionHeader('Automation rules'),
              const Spacer(),
              AppPrimaryButton(
                  label: 'New rule',
                  icon: Icons.add_rounded,
                  onPressed: () {}),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: _rules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final r = _rules[i];
                return _RuleCard(rule: r, onChanged: (v) {
                  setState(() => _rules[i]['enabled'] = v);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final Map<String, dynamic> rule;
  final ValueChanged<bool> onChanged;
  const _RuleCard({required this.rule, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final enabled = rule['enabled'] as bool;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: enabled
                ? AppColors.brand.withValues(alpha: 0.4)
                : context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_mode_rounded,
                  color: enabled ? AppColors.brand : context.textMutedColor,
                  size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(rule['name'] as String,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: context.textColor,
                        fontSize: 14)),
              ),
              Switch.adaptive(
                value: enabled,
                activeColor: AppColors.brand,
                onChanged: onChanged,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _RulePart(
                  label: 'WHEN',
                  value: rule['trigger'] as String,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: _RulePart(
                  label: 'THEN',
                  value: rule['action'] as String,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.bolt_rounded,
                  size: 12, color: context.textMutedColor),
              const SizedBox(width: 4),
              Text('${rule['runs']} runs this month',
                  style: TextStyle(
                      color: context.textMutedColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RulePart extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RulePart(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: context.textColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/cupertino.dart';
import '../../../app/design_system.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_widgets.dart';

/// Audit Logs — every admin action is logged here for compliance.
class AdminAuditLogsScreen extends ConsumerStatefulWidget {
  const AdminAuditLogsScreen({super.key});
  @override
  ConsumerState<AdminAuditLogsScreen> createState() =>
      _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState
    extends ConsumerState<AdminAuditLogsScreen> {
  String _severity = 'All';
  final _events = [
    {
      'actor': 'Admin Bob',
      'action': 'Refunded shipment',
      'target': 'APK2026052600004',
      'amount': 'SGD 76.00',
      'time': '2 min ago',
      'ip': '103.21.244.18',
      'severity': 'medium',
    },
    {
      'actor': 'Admin Alice',
      'action': 'Updated automation rule',
      'target': 'Repeat-customer discount',
      'amount': null,
      'time': '11 min ago',
      'ip': '103.21.244.20',
      'severity': 'low',
    },
    {
      'actor': 'System',
      'action': 'AI flagged customs review',
      'target': 'APK2026052600005 (HS 8517.62)',
      'amount': null,
      'time': '38 min ago',
      'ip': 'system',
      'severity': 'high',
    },
    {
      'actor': 'Admin Bob',
      'action': 'Bulk-imported 47 shipments',
      'target': 'CSV jun-batch.csv',
      'amount': null,
      'time': '1 hr ago',
      'ip': '103.21.244.18',
      'severity': 'low',
    },
    {
      'actor': 'System',
      'action': 'Unusual login detected',
      'target': 'admin@airpak.com (new IP)',
      'amount': null,
      'time': '3 hr ago',
      'ip': '198.51.100.7',
      'severity': 'critical',
    },
  ];

  Color _sevColor(String s) {
    switch (s) {
      case 'critical':
        return AppColors.danger;
      case 'high':
        return AppColors.warning;
      case 'medium':
        return AppColors.info;
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _severity == 'All'
        ? _events
        : _events
            .where((e) => (e['severity'] as String) == _severity.toLowerCase())
            .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionHeader('Audit logs'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: context.surfaceMutedColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final s in const ['All', 'Critical', 'High', 'Medium', 'Low'])
                      GestureDetector(
                        onTap: () => setState(() => _severity = s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _severity == s
                                ? context.surfaceColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(s,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _severity == s
                                      ? AppColors.brand
                                      : context.textMutedColor)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(4),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                    height: 1, color: context.dividerColor),
                itemBuilder: (_, i) {
                  final e = filtered[i];
                  final sev = e['severity'] as String;
                  return ListTile(
                    leading: Container(
                      width: 8,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _sevColor(sev),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(e['action'] as String,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: context.textColor)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _sevColor(sev).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(sev.toUpperCase(),
                              style: TextStyle(
                                  color: _sevColor(sev),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3)),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e['actor']} → ${e['target']}',
                              style: TextStyle(
                                  color: context.textMutedColor,
                                  fontSize: 11.5)),
                          Text('${e['ip']} · ${e['time']}',
                              style: TextStyle(
                                  color: context.textSubtleColor,
                                  fontSize: 10.5)),
                        ],
                      ),
                    ),
                    trailing: Text(
                      e['amount'] != null ? e['amount'] as String : '',
                      style: TextStyle(
                          color: context.textMutedColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

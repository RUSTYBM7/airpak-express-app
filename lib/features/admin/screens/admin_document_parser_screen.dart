import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/cupertino.dart';
import '../../../app/design_system.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/motion.dart';

/// Document Parser — drop a PDF/CSV/image of a commercial invoice,
/// HS code list, customs form, or address book and the parser
/// extracts structured rows for the shipment builder.
class AdminDocumentParserScreen extends ConsumerStatefulWidget {
  const AdminDocumentParserScreen({super.key});
  @override
  ConsumerState<AdminDocumentParserScreen> createState() =>
      _AdminDocumentParserScreenState();
}

class _AdminDocumentParserScreenState
    extends ConsumerState<AdminDocumentParserScreen> {
  bool _uploading = false;
  double _progress = 0;
  final _rows = [
    {
      'tracking': 'APK2026052600003',
      'name': 'Tan Wei Ming',
      'address': '12 Bukit Tinggi Rd, Singapore 289757',
      'weight': '2.4 kg',
      'value': 'SGD 184.50',
      'hs': '6204.42',
      'carrier': 'DHL',
      'confidence': 0.98,
    },
    {
      'tracking': 'APK2026052600004',
      'name': 'Lim Hui Ling',
      'address': '88 Orchard Rd, #12-04, Singapore 238862',
      'weight': '1.1 kg',
      'value': 'SGD 76.00',
      'hs': '7113.19',
      'carrier': 'FedEx',
      'confidence': 0.96,
    },
    {
      'tracking': 'APK2026052600005',
      'name': 'Raj Patel',
      'address': '15 Tras St, Singapore 079012',
      'weight': '5.0 kg',
      'value': 'SGD 312.00',
      'hs': '8517.62',
      'carrier': 'Aramex',
      'confidence': 0.93,
    },
  ];

  void _simulateUpload() {
    HapticService.medium();
    setState(() {
      _uploading = true;
      _progress = 0;
    });
    _progress = 0;
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return false;
      var done = false;
      setState(() {
        _progress += 0.04;
        if (_progress >= 1) {
          _progress = 1;
          _uploading = false;
          done = true;
        }
      });
      return !done;
    });
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
              const SectionHeader('Document parser'),
              const Spacer(),
              Text('${_rows.length} rows extracted',
                  style: TextStyle(
                      color: context.textMutedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          // Drop zone
          GestureDetector(
            onTap: _simulateUpload,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.surfaceMutedColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _uploading
                      ? AppColors.brand
                      : context.borderColor,
                  style: _uploading
                      ? BorderStyle.solid
                      : BorderStyle.solid,
                  width: _uploading ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: _uploading
                          ? AppColors.brandGradient
                          : null,
                      color: _uploading
                          ? null
                          : AppColors.brand.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                        _uploading
                            ? Icons.bolt_rounded
                            : Icons.cloud_upload_outlined,
                        color: _uploading ? Colors.white : AppColors.brand,
                        size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            _uploading
                                ? 'Extracting rows…'
                                : 'Drop PDF, CSV, or scan',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: context.textColor,
                                fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                            'Commercial invoices, HS lists, address books',
                            style: TextStyle(
                                color: context.textMutedColor,
                                fontSize: 11.5)),
                        if (_uploading) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: _progress,
                              minHeight: 4,
                              backgroundColor: context.borderColor,
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.brand),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowHeight: 36,
                  dataRowMinHeight: 48,
                  columnSpacing: 14,
                  columns: const [
                    DataColumn(label: Text('TRACKING')),
                    DataColumn(label: Text('RECIPIENT')),
                    DataColumn(label: Text('WEIGHT')),
                    DataColumn(label: Text('VALUE')),
                    DataColumn(label: Text('HS CODE')),
                    DataColumn(label: Text('CARRIER')),
                    DataColumn(label: Text('CONFIDENCE')),
                  ],
                  rows: _rows
                      .map((r) => DataRow(cells: [
                            DataCell(Text(r['tracking'] as String,
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700))),
                            DataCell(Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r['name'] as String,
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800)),
                                Text(r['address'] as String,
                                    style: TextStyle(
                                        color: context.textMutedColor,
                                        fontSize: 10)),
                              ],
                            )),
                            DataCell(Text(r['weight'] as String,
                                style: const TextStyle(fontSize: 11.5))),
                            DataCell(Text(r['value'] as String,
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800))),
                            DataCell(Text(r['hs'] as String,
                                style: TextStyle(
                                    color: context.textMutedColor,
                                    fontSize: 10.5,
                                    fontFamily: 'monospace'))),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.brand.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(r['carrier'] as String,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.brand)),
                            )),
                            DataCell(_ConfidenceBar(
                                v: r['confidence'] as double)),
                          ]))
                      .toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppPrimaryButton(
                  label: 'Create ${_rows.length} shipments',
                  icon: Icons.bolt_rounded,
                  onPressed: () {
                    HapticService.success();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final double v; // 0..1
  const _ConfidenceBar({required this.v});
  @override
  Widget build(BuildContext context) {
    final pct = (v * 100).round();
    final color = pct > 95
        ? AppColors.success
        : pct > 85
            ? AppColors.warning
            : AppColors.danger;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 5,
          decoration: BoxDecoration(
            color: context.borderColor,
            borderRadius: BorderRadius.circular(99),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: v,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('$pct%',
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}

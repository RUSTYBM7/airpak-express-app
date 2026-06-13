import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/cupertino.dart';
import '../../../app/design_system.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/motion.dart';

/// Voice Tools — call recordings, voice broadcasts, IVR menu editor,
/// speech-to-text transcripts of customer calls.
class AdminVoiceToolsScreen extends ConsumerStatefulWidget {
  const AdminVoiceToolsScreen({super.key});
  @override
  ConsumerState<AdminVoiceToolsScreen> createState() =>
      _AdminVoiceToolsScreenState();
}

class _AdminVoiceToolsScreenState
    extends ConsumerState<AdminVoiceToolsScreen> {
  final _recordings = [
    {
      'caller': '+65 8123 4567',
      'agent': 'Agent Bob',
      'duration': '04:21',
      'sentiment': 0.78,
      'topic': 'Customs duty query',
      'time': '2 min ago',
    },
    {
      'caller': '+60 12-345 6789',
      'agent': 'Agent Alice',
      'duration': '02:08',
      'sentiment': 0.92,
      'topic': 'Refund request — approved',
      'time': '11 min ago',
    },
    {
      'caller': '+62 812 9988 7766',
      'agent': 'Agent Bob',
      'duration': '06:54',
      'sentiment': 0.31,
      'topic': 'Lost parcel — escalated',
      'time': '38 min ago',
    },
    {
      'caller': '+81 90-1234-5678',
      'agent': 'Agent Alice',
      'duration': '01:42',
      'sentiment': 0.85,
      'topic': 'Tracking number lookup',
      'time': '1 hr ago',
    },
  ];

  bool _broadcasting = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionHeader('Voice tools'),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: context.surfaceMutedColor,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                          color: _broadcasting
                              ? AppColors.danger
                              : AppColors.success,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(_broadcasting ? 'Live broadcast' : 'Standby',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: context.textColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Quick actions row
          Row(
            children: [
              _VoiceActionCard(
                icon: Icons.record_voice_over_rounded,
                title: 'Start broadcast',
                subtitle: 'Reach 1,247 opted-in customers',
                color: AppColors.brand,
                busy: _broadcasting,
                onTap: () {
                  setState(() => _broadcasting = !_broadcasting);
                  HapticService.medium();
                },
              ),
              const SizedBox(width: 10),
              _VoiceActionCard(
                icon: Icons.menu_book_rounded,
                title: 'IVR menu',
                subtitle: 'Multi-language voice tree',
                color: AppColors.info,
                onTap: () {},
              ),
              const SizedBox(width: 10),
              _VoiceActionCard(
                icon: Icons.subtitles_rounded,
                title: 'Live transcripts',
                subtitle: '12 active calls',
                color: AppColors.success,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: _recordings.length,
                separatorBuilder: (_, __) => Divider(
                    height: 1, color: context.dividerColor),
                itemBuilder: (_, i) {
                  final r = _recordings[i];
                  return ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone_in_talk_rounded,
                          color: AppColors.brand, size: 18),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(r['caller'] as String,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: context.textColor,
                                  fontSize: 13.5)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.surfaceMutedColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(r['duration'] as String,
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: context.textMutedColor,
                                  fontFamily: 'monospace')),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${r['agent']} · ${r['topic']}',
                              style: TextStyle(
                                  color: context.textMutedColor,
                                  fontSize: 11.5)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                  color: (r['sentiment'] as double) > 0.6
                                      ? AppColors.success
                                      : (r['sentiment'] as double) > 0.4
                                          ? AppColors.warning
                                          : AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                  'Sentiment ${((r['sentiment'] as double) * 100).round()}%',
                                  style: TextStyle(
                                      color: context.textMutedColor,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(r['time'] as String,
                                  style: TextStyle(
                                      color: context.textSubtleColor,
                                      fontSize: 10.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_arrow_rounded),
                      onPressed: () {
                        HapticService.light();
                      },
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

class _VoiceActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool busy;
  final VoidCallback onTap;
  const _VoiceActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.busy = false,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: busy ? color : context.borderColor,
                  width: busy ? 1.4 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: busy
                      ? const Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.brand),
                        )
                      : Icon(icon, color: color, size: 16),
                ),
                const SizedBox(height: 8),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: context.textColor)),
                Text(subtitle,
                    style: TextStyle(
                        color: context.textMutedColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

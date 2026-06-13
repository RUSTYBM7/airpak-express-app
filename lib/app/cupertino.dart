import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design_system.dart';

/// ============================================================================
///  iOS / SwiftUI primitives — built to feel like a real SwiftUI app
/// ============================================================================

// ── Haptic service — iOS-style feedback everywhere ────────────────────

class HapticService {
  HapticService._();
  static void selection() => HapticFeedback.selectionClick();
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void success() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }
  static void warning() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }
  static void error() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }
}

// ── IosLargeNavBar — collapsing large title (SwiftUI style) ────────────

class IosLargeNavBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBack;
  final Color? background;
  final double expandedHeight;
  const IosLargeNavBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
    this.showBack = true,
    this.onBack,
    this.background,
    this.expandedHeight = 96,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: expandedHeight,
      collapsedHeight: kToolbarHeight,
      backgroundColor: background ?? context.bgColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      // iOS-style translucent nav bar with backdrop blur.
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: (background ?? context.bgColor)
                .withValues(alpha: isDark ? 0.72 : 0.78),
          ),
        ),
      ),
      iconTheme: IconThemeData(color: AppColors.brand),
      title: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 17,
          letterSpacing: -0.2,
          color: context.textColor,
        ),
        child: Text(title),
      ),
      leading: showBack
          ? (leading ??
              CupertinoButton(
                padding: const EdgeInsets.only(left: 8, right: 4),
                minSize: 0,
                onPressed: () {
                  HapticService.light();
                  onBack ?? Navigator.of(context).maybePop();
                },
                child: Icon(CupertinoIcons.back,
                    size: 22, color: AppColors.brand),
              ))
          : null,
      actions: actions,
    );
  }
}

// ── IosLargeTitle — SwiftUI .navigationTitle(.large) inline header ──────

class IosLargeTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  final EdgeInsets padding;
  const IosLargeTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 8, 4),
  });
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) leading!,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 34,
                      height: 1.1,
                      letterSpacing: -1.0,
                      color: context.textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: context.textMutedColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

// ── IosPullToRefresh — iOS rubber band refresh ─────────────────────────

class IosPullToRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Widget? header;
  const IosPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.header,
  });
  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
      onRefresh: () async {
        HapticService.medium();
        await onRefresh();
      },
      builder: (context, mode, pulledExtent, refreshTriggerPullDistance,
              refreshIndicatorExtent) {
        // Show a custom iOS-style indicator.
        final progress = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
        return Container(
          alignment: Alignment.center,
          height: refreshIndicatorExtent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.6 + 0.4 * progress,
                child: Opacity(
                  opacity: progress,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.brandGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.4 * progress),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_downward_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── IosSwipeActions — SwiftUI list swipe-to-reveal ────────────────────

class IosSwipeAction {
  final String label;
  final IconData icon;
  final Color background;
  final VoidCallback onTap;
  const IosSwipeAction({
    required this.label,
    required this.icon,
    required this.background,
    required this.onTap,
  });
}

class IosSwipeActions extends StatelessWidget {
  final Widget child;
  final List<IosSwipeAction> leadingActions;
  final List<IosSwipeAction> trailingActions;
  const IosSwipeActions({
    super.key,
    required this.child,
    this.leadingActions = const [],
    this.trailingActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (leadingActions.isEmpty && trailingActions.isEmpty) return child;
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.horizontal,
      resizeDuration: const Duration(milliseconds: 200),
      movementDuration: const Duration(milliseconds: 200),
      confirmDismiss: (dir) async {
        HapticService.medium();
        final isTrailing = dir == DismissDirection.startToEnd; // swipe right
        final actions =
            isTrailing ? leadingActions : trailingActions;
        if (actions.isEmpty) return false;
        // Show a Cupertino action sheet to pick which action to run.
        if (actions.length == 1) {
          actions.first.onTap();
          return true;
        }
        // Use CupertinoActionSheet via showCupertinoModalPopup.
        await showCupertinoModalPopup<void>(
          context: context,
          builder: (_) => CupertinoActionSheet(
            title: Text('Choose action'),
            actions: [
              for (final a in actions)
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(_).pop();
                    a.onTap();
                  },
                  child: Text(a.label,
                      style: TextStyle(color: a.background)),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(_).pop(),
              child: const Text('Cancel'),
            ),
          ),
        );
        return true;
      },
      background: _SwipeBg(
        alignment: Alignment.centerLeft,
        actions: leadingActions,
      ),
      secondaryBackground: _SwipeBg(
        alignment: Alignment.centerRight,
        actions: trailingActions,
      ),
      child: child,
    );
  }
}

class _SwipeBg extends StatelessWidget {
  final AlignmentGeometry alignment;
  final List<IosSwipeAction> actions;
  const _SwipeBg({required this.alignment, required this.actions});
  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return Container(color: Colors.transparent);
    }
    return Container(
      color: actions.first.background,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final a in actions) ...[
            Icon(a.icon, color: Colors.white, size: 22),
            const SizedBox(width: 6),
            Text(a.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

// ── IosContextMenu — long-press peek with iOS preview + actions ────────

class IosContextMenuItem {
  final String label;
  final IconData? icon;
  final bool destructive;
  final VoidCallback onTap;
  const IosContextMenuItem({
    required this.label,
    this.icon,
    this.destructive = false,
    required this.onTap,
  });
}

class IosContextMenu extends StatefulWidget {
  final Widget child;
  final List<IosContextMenuItem> actions;
  final Widget? preview;
  final VoidCallback? onLongPress;
  const IosContextMenu({
    super.key,
    required this.child,
    required this.actions,
    this.preview,
    this.onLongPress,
  });

  @override
  State<IosContextMenu> createState() => _IosContextMenuState();
}

class _IosContextMenuState extends State<IosContextMenu>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  void _onLongPressStart(LongPressStartDetails _) {
    HapticService.medium();
    setState(() => _pressed = true);
  }

  void _onLongPressEnd(LongPressEndDetails _) async {
    if (!_pressed) return;
    setState(() => _pressed = false);
    // Briefly show the preview, then show the action sheet.
    if (widget.preview != null) {
      // The Cupertino long-press menu uses peek-pop. We show a modal
      // with the preview, then a button to show actions.
    }
    if (widget.actions.isNotEmpty) {
      await _showSheet();
    }
  }

  Future<void> _showSheet() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          for (final a in widget.actions)
            CupertinoActionSheetAction(
              isDestructiveAction: a.destructive,
              onPressed: () {
                Navigator.of(ctx).pop();
                HapticService.light();
                a.onTap();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (a.icon != null) ...[
                    Icon(a.icon,
                        size: 18,
                        color: a.destructive
                            ? CupertinoColors.systemRed
                            : CupertinoColors.label),
                    const SizedBox(width: 8),
                  ],
                  Text(a.label),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: () => setState(() => _pressed = false),
      onTap: () => HapticService.selection(),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ── IosBottomSheet — with detents (small / medium / large) ────────────

enum IosSheetDetent { small, medium, large }

Future<T?> showIosBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  IosSheetDetent initialDetent = IosSheetDetent.medium,
  List<IosSheetDetent> detents = const [
    IosSheetDetent.medium,
    IosSheetDetent.large,
  ],
  bool isDismissible = true,
  bool showDragHandle = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _IosSheet(
      initialDetent: initialDetent,
      detents: detents,
      showDragHandle: showDragHandle,
      child: child,
    ),
  );
}

class _IosSheet extends StatefulWidget {
  final Widget child;
  final IosSheetDetent initialDetent;
  final List<IosSheetDetent> detents;
  final bool showDragHandle;
  const _IosSheet({
    required this.child,
    required this.initialDetent,
    required this.detents,
    required this.showDragHandle,
  });
  @override
  State<_IosSheet> createState() => _IosSheetState();
}

class _IosSheetState extends State<_IosSheet> {
  late DraggableScrollableController _ctl =
      DraggableScrollableController();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  double _heightFor(IosSheetDetent d, double maxH) {
    switch (d) {
      case IosSheetDetent.small:
        return maxH * 0.28;
      case IosSheetDetent.medium:
        return maxH * 0.55;
      case IosSheetDetent.large:
        return maxH * 0.92;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height;
    final initial = _heightFor(widget.initialDetent, maxH);
    final minH = _heightFor(widget.detents.first, maxH);
    final maxHeight = _heightFor(widget.detents.last, maxH);

    return DraggableScrollableSheet(
      controller: _ctl,
      initialChildSize: initial / maxH,
      minChildSize: minH / maxH,
      maxChildSize: maxHeight / maxH,
      expand: false,
      builder: (ctx, scrollCtl) {
        return Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showDragHandle)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              Expanded(
                child: ListView(
                  controller: scrollCtl,
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [widget.child],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── IosSegmentedControl — SwiftUI Picker.segmented ────────────────────

class IosSegmentedControl<T> extends StatelessWidget {
  final Map<T, String> options;
  final T? groupValue;
  final ValueChanged<T> onChanged;
  final IconData? Function(T)? iconOf;
  const IosSegmentedControl({
    super.key,
    required this.options,
    required this.groupValue,
    required this.onChanged,
    this.iconOf,
  });
  @override
  Widget build(BuildContext context) {
    final keys = options.keys.toList();
    return Container(
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: context.surfaceMutedColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final k in keys)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticService.selection();
                  onChanged(k);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: groupValue == k
                        ? context.surfaceColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: groupValue == k
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (iconOf != null && iconOf!(k) != null) ...[
                          Icon(iconOf!(k),
                              size: 14,
                              color: groupValue == k
                                  ? context.textColor
                                  : context.textMutedColor),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          options[k]!,
                          style: TextStyle(
                            color: groupValue == k
                                ? context.textColor
                                : context.textMutedColor,
                            fontSize: 13,
                            fontWeight: groupValue == k
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── IosSearchBar — SwiftUI .searchable style ──────────────────────────

class IosSearchBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final VoidCallback? onCancel;
  const IosSearchBar({
    super.key,
    this.hint = 'Search',
    this.onChanged,
    this.controller,
    this.onCancel,
  });
  @override
  State<IosSearchBar> createState() => _IosSearchBarState();
}

class _IosSearchBarState extends State<IosSearchBar> {
  late TextEditingController _ctrl =
      widget.controller ?? TextEditingController();

  @override
  void dispose() {
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: context.surfaceMutedColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(Icons.search_rounded, color: context.textMutedColor, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: widget.onChanged,
              style: TextStyle(
                  color: context.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
              cursorColor: AppColors.brand,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: TextStyle(
                    color: context.textSubtleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          if (_ctrl.text.isNotEmpty)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minSize: 0,
              onPressed: () {
                _ctrl.clear();
                widget.onChanged?.call('');
                setState(() {});
                HapticService.light();
              },
              child: Icon(Icons.cancel_rounded,
                  color: context.textMutedColor, size: 18),
            ),
        ],
      ),
    );
  }
}

// ── IosActivityView — iOS-style share sheet (uses cupertino modal) ─────

Future<void> showIosShareSheet({
  required BuildContext context,
  required String title,
  String? message,
  String? url,
}) async {
  HapticService.light();
  await showCupertinoModalPopup<void>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(title),
      message: message != null ? Text(message) : null,
      actions: [
        if (url != null)
          CupertinoActionSheetAction(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.of(ctx).pop();
              HapticService.success();
            },
            child: const Text('Copy link'),
          ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(ctx).pop();
          },
          child: const Text('Share via Messages'),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(ctx).pop();
          },
          child: const Text('Share via Mail'),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(ctx).pop();
          },
          child: const Text('Add to Reading List'),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.of(ctx).pop(),
        child: const Text('Cancel'),
      ),
    ),
  );
}

// ── IosDatePicker — wraps CupertinoDatePicker ────────────────────────

Future<DateTime?> showIosDatePicker(
  BuildContext context, {
  DateTime? initial,
  DateTime? minimumDate,
  DateTime? maximumDate,
  String title = 'Select date',
}) async {
  DateTime tempPicked = initial ?? DateTime.now();
  final result = await showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (ctx) => Container(
      height: 280,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(ctx).pop(tempPicked),
                  child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: initial ?? DateTime.now(),
              minimumDate: minimumDate,
              maximumDate: maximumDate,
              onDateTimeChanged: (d) => tempPicked = d,
            ),
          ),
        ],
      ),
    ),
  );
  return result;
}

// ── IosStepper — SwiftUI Stepper ──────────────────────────────────────

class IosStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const IosStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn(
          icon: Icons.remove_rounded,
          onTap: () {
            if (value > min) {
              HapticService.selection();
              onChanged(value - 1);
            }
          },
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 40),
          child: Text(
            value.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _Btn(
          icon: Icons.add_rounded,
          onTap: () {
            if (value < max) {
              HapticService.selection();
              onChanged(value + 1);
            }
          },
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 32,
      onPressed: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.surfaceMutedColor,
        ),
        child: Icon(icon, size: 16, color: context.textColor),
      ),
    );
  }
}

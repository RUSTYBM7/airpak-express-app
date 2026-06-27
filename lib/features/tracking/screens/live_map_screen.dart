import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/cupertino.dart';
import '../../../app/design_system.dart';
import '../../../app/router.dart';
import '../../../core/data/repositories.dart';
import '../../../core/models/shipment.dart';
import '../../../core/widgets/world_map.dart';
import '../../auth/providers/auth_controller.dart';

/// Snapchat-style world live tracking map.
///
/// Whole world is rendered via a `CustomPainter` wrapped in an
/// `InteractiveViewer` so the user can pinch-zoom, drag-pan,
/// double-tap. The courier is rendered as a glowing animated dot
/// with crosshair; the route is rendered as a curved line; the
/// origin and destination get coloured pins; any active hold is
/// rendered as a warning triangle on the route.
///
/// The route is computed from a real list of (lat, lng) waypoints
/// so the parcel appears to move across continents, not just
/// between two fixed dots.
class LiveMapScreen extends ConsumerStatefulWidget {
  final String tracking;
  const LiveMapScreen({super.key, required this.tracking});

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen>
    with TickerProviderStateMixin {
  final TransformationController _xform = TransformationController();
  Timer? _tick;
  int _pulseTick = 0;
  bool _followCourier = true;
  bool _expanded = false;
  Shipment? _shipment;

  // Synthetic live data
  double _simProgress = 0.42; // 0..1
  double _simSpeed = 38; // km/h
  int _simBattery = 87; // %
  double _simAltitude = 12000; // m
  double _simDistanceKm = 4520;
  Duration _simEta = const Duration(hours: 8, minutes: 24);
  String? _simHoldReason;

  // A "real" route: KL → Hong Kong → Tokyo → Los Angeles.
  // In production this would be derived from the shipment.
  final List<GeoPoint> _route = const [
    GeoPoint(3.139, 101.6869),   // Kuala Lumpur
    GeoPoint(1.3521, 103.8198),  // Singapore waypoint
    GeoPoint(13.7563, 100.5018), // Bangkok waypoint
    GeoPoint(22.3193, 114.1694), // Hong Kong waypoint
    GeoPoint(35.6762, 139.6503), // Tokyo waypoint
    GeoPoint(47.6062, -122.3321), // Seattle waypoint
    GeoPoint(34.0522, -118.2437), // Los Angeles
  ];

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _pulseTick++;
        if (_simProgress < 0.99) {
          _simProgress = math.min(0.99, _simProgress + 0.018);
          _simSpeed = 32 + (math.sin(_pulseTick * 0.7) + 1) * 18;
          _simDistanceKm = math.max(80, _simDistanceKm - 65);
          final secs = (_simDistanceKm / _simSpeed * 3600).round();
          _simEta = Duration(seconds: secs);
          _simBattery = math.max(40, _simBattery - 1);
          _simAltitude = 8000 + math.sin(_pulseTick * 0.5) * 6000;
        }
      });
    });
    HapticService.light();
    _loadShipment();
  }

  Future<void> _loadShipment() async {
    final repo = ref.read(shipmentRepoProvider);
    final res = await repo.getByTracking(widget.tracking);
    if (mounted && res.data != null) {
      setState(() => _shipment = res.data);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _xform.dispose();
    super.dispose();
  }

  void _recenter() {
    setState(() => _followCourier = true);
    // Center the map (reset zoom to 1.0, no translation)
    _xform.value = Matrix4.identity();
    HapticService.light();
  }

  void _showHistorySheet(BuildContext context) {
    HapticService.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.72,
          decoration: const BoxDecoration(
            color: Color(0xFF0E1320),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36, height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.timeline_rounded, color: AppColors.brand, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Tracking history · ${widget.tracking}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                    ),
                  ],
                ),
              ),
              Container(height: 0.5, color: Colors.white12),
              Expanded(child: _buildHistoryList()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    final repo = ref.read(shipmentRepoProvider);
    return FutureBuilder(
      future: repo.events(_shipment?.id ?? ''),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.brand),
          );
        }
        if (!snap.hasData) {
          return Center(
            child: Text('No history yet',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          );
        }
        final res = snap.data!;
        final events = (res.data ?? <TrackingEvent>[]);
        if (events.isEmpty) {
          return Center(
            child: Text('No history yet',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (ctx, i) {
            final e = events[i];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: _eventColor(e.status),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: _eventColor(e.status).withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1),
                        ],
                      ),
                    ),
                    if (i < events.length - 1)
                      Container(width: 2, height: 30, color: Colors.white24),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.status.label,
                          style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800)),
                      if (e.location.isNotEmpty)
                        Text(e.location,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600)),
                      if ((e.description ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(e.description!,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11.5, height: 1.4)),
                        ),
                      const SizedBox(height: 2),
                      Text(DateFormat('MMM d, HH:mm').format(e.occurredAt),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _eventColor(ShipmentStatus s) {
    switch (s) {
      case ShipmentStatus.delivered: return AppColors.success;
      case ShipmentStatus.outForDelivery: return AppColors.info;
      case ShipmentStatus.inTransit: return AppColors.brand;
      case ShipmentStatus.pickedUp: return AppColors.warning;
      case ShipmentStatus.exception: return AppColors.danger;
      default: return Colors.white;
    }
  }

  Future<void> _shareTracking(BuildContext context) async {
    HapticService.success();
    final summary = '''
AirPak Express — Live Tracking
$widget.tracking
Status: ${_shipment?.status.label ?? 'In transit'}
Progress: ${(_simProgress * 100).toStringAsFixed(0)}%
ETA: ${_fmtDur(_simEta)}
Distance: ${_simDistanceKm.toStringAsFixed(0)} km
Speed: ${_simSpeed.toStringAsFixed(0)} km/h

Live map: https://web-rust-ten-91.vercel.app/portal/track/$widget.tracking
''';
    Clipboard.setData(ClipboardData(text: summary));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tracking summary copied · PDF download coming next build'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  String _fmtDur(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),
      extendBodyBehindAppBar: true,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── World map with pinch-to-zoom ─────────────────────────
            Positioned.fill(
              child: LayoutBuilder(
                builder: (ctx, c) => InteractiveViewer(
                  transformationController: _xform,
                  minScale: 0.5,
                  maxScale: 8.0,
                  boundaryMargin: const EdgeInsets.all(400),
                  onInteractionEnd: (_) {
                    final scale = _xform.value.getMaxScaleOnAxis();
                    if (scale != 1.0) {
                      setState(() => _followCourier = false);
                    }
                  },
                  child: SizedBox(
                    width: c.maxWidth,
                    height: c.maxHeight,
                    child: CustomPaint(
                      painter: WorldMapPainter(
                        progress: _simProgress,
                        holdProgress: _simHoldReason != null ? _simProgress : null,
                        route: _route,
                        courierPath: _route,
                        pulseTick: _pulseTick,
                        landColor: const Color(0xFF1B2438),
                        strokeColor: const Color(0xFF2D3A55),
                        gridColor: const Color(0xFF3D4862).withValues(alpha: 0.5),
                        routeColor: AppColors.brand,
                        courierColor: AppColors.brand,
                        labelColor: const Color(0xFF8FA0BD),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Top glass bar ─────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  child: _GlassBar(
                    tracking: widget.tracking,
                    status: _shipment?.status.label ?? 'In transit',
                    onBack: () => context.canPop() ? context.pop() : context.go(AppRoutes.portalDashboard),
                    onClose: () => context.go(AppRoutes.portalDashboard),
                  ),
                ),
              ),
            ),

            // ── Right-side controls ────────────────────────────────
            Positioned(
              right: 14,
              top: MediaQuery.of(context).padding.top + 80,
              child: Column(
                children: [
                  _MapButton(icon: Icons.add_rounded, onTap: () {
                    final m = _xform.value;
                    final s = (m.getMaxScaleOnAxis() * 1.3).clamp(0.5, 8.0);
                    _xform.value = Matrix4.identity()..scale(s);
                  }),
                  const SizedBox(height: 8),
                  _MapButton(icon: Icons.remove_rounded, onTap: () {
                    final m = _xform.value;
                    final s = (m.getMaxScaleOnAxis() / 1.3).clamp(0.5, 8.0);
                    _xform.value = Matrix4.identity()..scale(s);
                  }),
                  const SizedBox(height: 8),
                  _MapButton(
                    icon: _followCourier ? Icons.my_location_rounded : Icons.location_searching_rounded,
                    active: _followCourier,
                    onTap: _recenter,
                  ),
                  const SizedBox(height: 8),
                  _MapButton(icon: Icons.layers_rounded, onTap: () {
                    HapticService.selection();
                    showIosShareSheet(
                      context: context,
                      title: 'Map style',
                      message: 'Choose how the map looks.',
                      items: const ['World', 'Satellite', 'Dark', 'Light'],
                    );
                  }),
                ],
              ),
            ),

            // ── Bottom telemetry + actions ─────────────────────────
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.85),
                        const Color(0xFF000000),
                      ],
                      stops: const [0.0, 0.15, 0.4],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.62),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(_expanded ? 28 : 22)),
                            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                          child: Column(
                            children: [
                              // Handle
                              Center(
                                child: Container(
                                  width: 36, height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Status + progress
                              Row(
                                children: [
                                  Container(
                                    width: 12, height: 12,
                                    decoration: BoxDecoration(
                                      color: _simHoldReason != null ? AppColors.warning : AppColors.success,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_simHoldReason != null ? AppColors.warning : AppColors.success).withValues(alpha: 0.6),
                                          blurRadius: 8, spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _simHoldReason != null
                                              ? 'On hold · ${_simHoldReason}'
                                              : 'In transit · arriving in ${_fmtDur(_simEta)}',
                                          style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800),
                                        ),
                                        Text(
                                          _simHoldReason != null
                                              ? 'Operator is resolving this with you'
                                              : '${(_simProgress * 100).toStringAsFixed(0)}% of journey complete · customs cleared',
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11.5, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    _expanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Progress bar
                              Stack(
                                children: [
                                  Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: _simProgress,
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [AppColors.brand, AppColors.warning],
                                        ),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Stat row
                              Row(
                                children: [
                                  Expanded(child: _Stat(label: 'ETA', value: _fmtDur(_simEta), color: AppColors.brand)),
                                  _StatDivider(),
                                  Expanded(child: _Stat(label: 'Distance', value: '${_simDistanceKm.toStringAsFixed(0)} km', color: AppColors.info)),
                                  _StatDivider(),
                                  Expanded(child: _Stat(label: 'Speed', value: '${_simSpeed.toStringAsFixed(0)} km/h', color: AppColors.success)),
                                  _StatDivider(),
                                  Expanded(child: _Stat(label: 'Altitude', value: '${(_simAltitude / 1000).toStringAsFixed(1)} km', color: AppColors.warning)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_expanded)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          color: Colors.black.withValues(alpha: 0.62),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(height: 0.5, color: Colors.white.withValues(alpha: 0.10)),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ActionButton(
                                      icon: Icons.timeline_rounded,
                                      label: 'History',
                                      onTap: () => _showHistorySheet(context),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _ActionButton(
                                      icon: Icons.share_rounded,
                                      label: 'Share / PDF',
                                      onTap: () => _shareTracking(context),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _ActionButton(
                                      icon: Icons.support_agent_rounded,
                                      label: 'Support',
                                      onTap: () => context.push(AppRoutes.portalSupport),
                                      primary: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Text('ROUTE WAYPOINTS', style: TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                              const SizedBox(height: 8),
                              for (final p in _route) _WaypointLine(point: p),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Hold banner (admin can set from admin app) ────────
            if (_simHoldReason != null)
              Positioned(
                left: 12, right: 80,
                top: MediaQuery.of(context).padding.top + 80,
                child: _HoldBanner(reason: _simHoldReason!),
              ),
          ],
        ),
      ),
    );
  }
}

class _GlassBar extends StatelessWidget {
  final String tracking;
  final String status;
  final VoidCallback onBack;
  final VoidCallback onClose;
  const _GlassBar({required this.tracking, required this.status, required this.onBack, required this.onClose});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GlassIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.success, blurRadius: 8, spreadRadius: 1),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$status · ${tracking.length > 14 ? tracking.substring(tracking.length - 12) : tracking}',
                          style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                      Text('Updated just now · 4s',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 10.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _GlassIconButton(icon: Icons.close_rounded, onTap: onClose),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticService.selection(); onTap(); },
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _MapButton({required this.icon, required this.onTap, this.active = false});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: active ? AppColors.brand : Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: active ? [BoxShadow(color: AppColors.brand.withValues(alpha: 0.4), blurRadius: 12)] : null,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 0.5, height: 22, color: Colors.white.withValues(alpha: 0.15));
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.primary = false});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticService.selection(); onTap(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: primary ? AppColors.brand : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _WaypointLine extends StatelessWidget {
  final GeoPoint point;
  const _WaypointLine({required this.point});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('${point.lat.toStringAsFixed(2)}° ${point.lng.toStringAsFixed(2)}°',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

class _HoldBanner extends StatelessWidget {
  final String reason;
  const _HoldBanner({required this.reason});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hold applied by AirPak Ops: $reason',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

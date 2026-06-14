import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

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
import '../../../core/widgets/motion.dart';
import '../../auth/providers/auth_controller.dart';

/// Snapchat-style live tracking map.
///
/// The whole map is a `CustomPainter` drawn into a `InteractiveViewer`
/// so the user can pinch to zoom, drag to pan, and double-tap to zoom
/// in — exactly like Snapchat's Snap Map.
///
/// The current parcel position is rendered as a glowing animated dot
/// that pulses every second. The route is rendered as a curved line
/// from origin → present → destination with waypoint pins.
///
/// A small bottom sheet shows the live telemetry (ETA, distance,
/// speed, courier battery, altitude) and the latest 4 events.
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

  // Synthetic live data — refreshed every 4s to feel "live".
  double _simProgress = 0.65; // 0..1
  double _simSpeed = 38; // km/h
  int _simBattery = 87; // %
  double _simAltitude = 42; // m
  double _simDistanceKm = 12.4;
  Duration _simEta = const Duration(minutes: 5, seconds: 42);
  String? _simHoldReason;

  static const _lat0 = 3.1390; // Kuala Lumpur
  static const _lat1 = -6.2088; // Jakarta
  // Map a [0..1] t along the route to a (lat, lng) using a great-circle-ish curve.
  Offset _routeAt(double t) {
    final l0 = _lat0;
    final l1 = _lat1;
    // Curve via Singapore midpoint for visual interest
    final midLat = 1.3521;
    final midLng = 103.8198;
    final l = (1 - t) * l0 + t * l1;
    final lng = (1 - t) * 101.6869 + t * 106.8456;
    // bend toward midpoint
    final bend = math.sin(t * math.pi) * 0.20;
    return Offset(lng + bend * 5, l + bend * 2);
  }

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _pulseTick++;
        if (_simProgress < 0.98) {
          _simProgress = math.min(0.98, _simProgress + 0.012);
          _simSpeed = 32 + (math.sin(_pulseTick * 0.7) + 1) * 8;
          _simDistanceKm = math.max(0.4, _simDistanceKm - 0.6);
          final secs = (_simDistanceKm / _simSpeed * 3600).round();
          _simEta = Duration(seconds: secs);
          _simBattery = math.max(40, _simBattery - 1);
          _simAltitude = 30 + math.sin(_pulseTick * 0.5) * 25;
        }
      });
    });
    HapticService.light();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _xform.dispose();
    super.dispose();
  }

  void _zoom(double delta) {
    final m = _xform.value;
    final scale = (m.getMaxScaleOnAxis() * (1 + delta)).clamp(0.6, 6.0);
    _xform.value = Matrix4.identity()..scale(scale);
  }

  void _resetView() {
    _xform.value = Matrix4.identity();
    HapticService.selection();
  }

  void _recenter() {
    // Recenter on the courier's current location
    setState(() => _followCourier = true);
    final courier = _routeAt(_simProgress);
    // Compute the canvas-space position of the courier
    final canvasPos = _toCanvas(courier);
    // Center the viewport on the courier
    final size = MediaQuery.of(context).size;
    final tx = (size.width / 2 - canvasPos.dx) * 1.6;
    final ty = (size.height / 2 - canvasPos.dy) * 1.6;
    _xform.value = Matrix4.identity()
      ..scale(1.6)
      ..translate(tx / 1.6, ty / 1.6);
    HapticService.light();
  }

  // Convert a (lng, lat) to a normalized canvas coordinate
  Offset _toCanvas(Offset geo) {
    final size = MediaQuery.of(context).size;
    final lng = geo.dx;
    final lat = geo.dy;
    // Visible window: lng 95..115, lat -10..6
    final x = (lng - 95) / 20;
    final y = 1 - (lat + 10) / 16; // flip Y for canvas
    return Offset(x * size.width, y * size.height);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      extendBodyBehindAppBar: true,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
          // ── Map canvas with pinch-to-zoom ──────────────────────────
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _xform,
              minScale: 0.6,
              maxScale: 6.0,
              boundaryMargin: const EdgeInsets.all(200),
              onInteractionEnd: (_) {
                final scale = _xform.value.getMaxScaleOnAxis();
                if (scale != 1.6) {
                  setState(() => _followCourier = false);
                }
              },
              child: LayoutBuilder(
                builder: (ctx, c) => SizedBox(
                  width: c.maxWidth,
                  height: c.maxHeight,
                  child: CustomPaint(
                    painter: _SnapMapPainter(
                      progress: _simProgress,
                      pulseTick: _pulseTick,
                      toCanvas: _toCanvas,
                      routeAt: _routeAt,
                      isDark: true,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Top glass bar ─────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: _GlassBar(
                tracking: widget.tracking,
                onBack: () => context.canPop() ? context.pop() : context.go(AppRoutes.portalDashboard),
                onClose: () => context.go(AppRoutes.portalDashboard),
              ),
            ),
          ),

          // ── Right-side controls ──────────────────────────────────
          Positioned(
            right: 14,
            top: MediaQuery.of(context).padding.top + 80,
            child: Column(
              children: [
                _MapButton(icon: Icons.add_rounded, onTap: () => _zoom(0.3)),
                const SizedBox(height: 8),
                _MapButton(icon: Icons.remove_rounded, onTap: () => _zoom(-0.3)),
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
                    items: const ['Map', 'Satellite', 'Dark', 'Light'],
                  );
                }),
              ],
            ),
          ),

          // ── Bottom telemetry + actions ───────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SafeArea(
              top: false,
              child: _LiveTelemetryCard(
                progress: _simProgress,
                speed: _simSpeed,
                battery: _simBattery,
                altitude: _simAltitude,
                distanceKm: _simDistanceKm,
                eta: _simEta,
                holdReason: _simHoldReason,
                tracking: widget.tracking,
                origin: _routeAt(0),
                present: _routeAt(_simProgress),
                destination: _routeAt(1),
                onShare: () {
                  HapticService.success();
                  Clipboard.setData(ClipboardData(text: widget.tracking));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tracking number copied')),
                  );
                },
                onSupport: () => context.push(AppRoutes.portalSupport),
              ),
            ),
          ),

          // ── Hold banner (admin can set from admin app) ──────────
          if (_simHoldReason != null)
            Positioned(
              left: 12, right: 80, top: MediaQuery.of(context).padding.top + 80,
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
  final VoidCallback onBack;
  final VoidCallback onClose;
  const _GlassBar({required this.tracking, required this.onBack, required this.onClose});
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
              color: Colors.black.withValues(alpha: 0.45),
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
                      Text('Live · ${tracking.length > 14 ? tracking.substring(tracking.length - 12) : tracking}',
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
          color: Colors.black.withValues(alpha: 0.45),
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

class _LiveTelemetryCard extends StatefulWidget {
  final double progress;
  final double speed;
  final int battery;
  final double altitude;
  final double distanceKm;
  final Duration eta;
  final String? holdReason;
  final String tracking;
  final Offset origin;
  final Offset present;
  final Offset destination;
  final VoidCallback onShare;
  final VoidCallback onSupport;
  const _LiveTelemetryCard({
    required this.progress,
    required this.speed,
    required this.battery,
    required this.altitude,
    required this.distanceKm,
    required this.eta,
    required this.holdReason,
    required this.tracking,
    required this.origin,
    required this.present,
    required this.destination,
    required this.onShare,
    required this.onSupport,
  });
  @override
  State<_LiveTelemetryCard> createState() => _LiveTelemetryCardState();
}

class _LiveTelemetryCardState extends State<_LiveTelemetryCard> {
  bool _expanded = false;

  String _fmtDur(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.62),
          borderRadius: BorderRadius.vertical(top: Radius.circular(_expanded ? 28 : 22)),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
        ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
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
                          color: widget.holdReason != null ? AppColors.warning : AppColors.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (widget.holdReason != null ? AppColors.warning : AppColors.success).withValues(alpha: 0.6),
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
                              widget.holdReason != null
                                  ? 'On hold · ${widget.holdReason}'
                                  : 'In transit · arriving in ${_fmtDur(widget.eta)}',
                              style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              widget.holdReason != null
                                  ? 'Operator is resolving this with you'
                                  : 'Customs cleared · out for linehaul',
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
                        widthFactor: widget.progress,
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
                      Expanded(child: _Stat(label: 'ETA', value: _fmtDur(widget.eta), color: AppColors.brand)),
                      _StatDivider(),
                      Expanded(child: _Stat(label: 'Distance', value: '${widget.distanceKm.toStringAsFixed(1)} km', color: AppColors.info)),
                      _StatDivider(),
                      Expanded(child: _Stat(label: 'Speed', value: '${widget.speed.toStringAsFixed(0)} km/h', color: AppColors.success)),
                      _StatDivider(),
                      Expanded(child: _Stat(label: 'Battery', value: '${widget.battery}%', color: widget.battery > 60 ? AppColors.success : AppColors.warning)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 0.5, color: Colors.white.withValues(alpha: 0.10)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.share_rounded,
                          label: 'Share',
                          onTap: widget.onShare,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.support_agent_rounded,
                          label: 'Support',
                          onTap: widget.onSupport,
                          primary: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('RECENT EVENTS', style: TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                  const SizedBox(height: 8),
                  _EventLine(
                    title: 'Departed Jakarta hub',
                    time: '2 min ago',
                    icon: Icons.flight_takeoff_rounded,
                    color: AppColors.info,
                  ),
                  _EventLine(
                    title: 'Customs cleared',
                    time: '1 hr ago',
                    icon: Icons.gavel_rounded,
                    color: AppColors.success,
                  ),
                  _EventLine(
                    title: 'Loaded onto LH-203',
                    time: '4 hr ago',
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.brand,
                  ),
                  _EventLine(
                    title: 'Picked up in Kuala Lumpur',
                    time: 'yesterday',
                    icon: Icons.local_shipping_rounded,
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
        ],
      ),
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

class _EventLine extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color color;
  const _EventLine({required this.title, required this.time, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 13),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700))),
          Text(time, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11, fontWeight: FontWeight.w600)),
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

// ── Custom painter for the Snapchat-style map ────────────────────────

class _SnapMapPainter extends CustomPainter {
  final double progress;
  final int pulseTick;
  final Offset Function(Offset) toCanvas;
  final Offset Function(double) routeAt;
  final bool isDark;
  _SnapMapPainter({
    required this.progress,
    required this.pulseTick,
    required this.toCanvas,
    required this.routeAt,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background — soft midnight blue
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B1220), Color(0xFF1A1F2E), Color(0xFF0E1320)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Subtle lat/lng grid
    final grid = Paint()
      ..color = const Color(0xFF3D4862).withValues(alpha: 0.7)
      ..strokeWidth = 0.6;
    for (int i = 0; i <= 10; i++) {
      final x = i * size.width / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (int i = 0; i <= 8; i++) {
      final y = i * size.height / 8;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Land masses (rough outlines of Malay Peninsula, Sumatra, Borneo, Java)
    _drawLandMass(canvas, size, [
      // Malay Peninsula (slim diagonal)
      Offset(0.55, 0.05), Offset(0.62, 0.10), Offset(0.60, 0.20),
      Offset(0.58, 0.32), Offset(0.55, 0.45), Offset(0.56, 0.55),
      Offset(0.58, 0.62), Offset(0.61, 0.70), Offset(0.62, 0.78),
    ], const Color(0xFF2A3A52));
    // Sumatra (long diagonal island)
    _drawLandMass(canvas, size, [
      Offset(0.50, 0.62), Offset(0.53, 0.68), Offset(0.60, 0.74),
      Offset(0.68, 0.78), Offset(0.74, 0.83), Offset(0.78, 0.88),
      Offset(0.76, 0.92), Offset(0.70, 0.90), Offset(0.62, 0.86),
      Offset(0.55, 0.80), Offset(0.50, 0.72),
    ], const Color(0xFF2A3A52));
    // Borneo (round blob top-right)
    _drawLandMass(canvas, size, [
      Offset(0.78, 0.32), Offset(0.85, 0.30), Offset(0.90, 0.34),
      Offset(0.92, 0.42), Offset(0.90, 0.50), Offset(0.85, 0.54),
      Offset(0.78, 0.50), Offset(0.74, 0.42),
    ], const Color(0xFF2A3A52));
    // Java (long thin bottom)
    _drawLandMass(canvas, size, [
      Offset(0.62, 0.90), Offset(0.70, 0.92), Offset(0.78, 0.94),
      Offset(0.84, 0.96), Offset(0.88, 0.98), Offset(0.84, 0.99),
      Offset(0.76, 0.98), Offset(0.68, 0.96), Offset(0.62, 0.94),
    ], const Color(0xFF2A3A52));

    // City labels (faint)
    _drawCityLabel(canvas, size, 'KUALA LUMPUR', 0.55, 0.30, const Color(0xFF8FA0BD));
    _drawCityLabel(canvas, size, 'SINGAPORE',   0.59, 0.62, const Color(0xFF8FA0BD));
    _drawCityLabel(canvas, size, 'JAKARTA',     0.78, 0.94, const Color(0xFF8FA0BD));
    _drawCityLabel(canvas, size, 'Kuching',     0.84, 0.46, const Color(0xFF6E7E99));
    _drawCityLabel(canvas, size, 'Medan',       0.55, 0.74, const Color(0xFF6E7E99));

    // Route line — origin → present → destination
    final routePts = <Offset>[];
    for (int i = 0; i <= 100; i++) {
      routePts.add(routeAt(i / 100));
    }
    // Background grey line (full route)
    final routePath = Path()..moveTo(routePts.first.dx, routePts.first.dy);
    for (int i = 1; i < routePts.length; i++) {
      routePath.lineTo(routePts[i].dx, routePts[i].dy);
    }
    final greyPaint = Paint()
      ..color = const Color(0xFF3B475E)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(routePath, greyPaint);

    // Active portion (gradient) — up to progress
    final activePath = Path()..moveTo(routePts.first.dx, routePts.first.dy);
    final endIdx = (routePts.length * progress).floor().clamp(1, routePts.length - 1);
    for (int i = 1; i <= endIdx; i++) {
      activePath.lineTo(routePts[i].dx, routePts[i].dy);
    }
    final activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.brand, AppColors.warning],
      ).createShader(Rect.fromPoints(routePts.first, routePts[endIdx]))
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(activePath, activePaint);

    // Dashed forecast line (progress → 1)
    if (progress < 0.95) {
      final dashPath = Path()..moveTo(routePts[endIdx].dx, routePts[endIdx].dy);
      for (int i = endIdx + 1; i < routePts.length; i++) {
        dashPath.lineTo(routePts[i].dx, routePts[i].dy);
      }
      _drawDashed(canvas, dashPath, const Color(0xFF56607A), 2.5, 6, 4);
    }

    // Origin pin
    final origin = routeAt(0);
    _drawPin(canvas, origin, const Color(0xFF22C55E), Icons.circle_rounded, 'Origin');
    // Destination pin
    final dest = routeAt(1);
    _drawPin(canvas, dest, const Color(0xFFEF4444), Icons.location_on_rounded, 'Destination');
    // Current courier position — pulsing dot
    final present = routeAt(progress);
    _drawPulseDot(canvas, present, pulseTick);
  }

  void _drawLandMass(Canvas canvas, Size size, List<Offset> points, Color color) {
    final p = Path();
    if (points.isEmpty) return;
    p.moveTo(points.first.dx * size.width, points.first.dy * size.height);
    for (int i = 1; i < points.length; i++) {
      p.lineTo(points[i].dx * size.width, points[i].dy * size.height);
    }
    p.close();
    final paint = Paint()..color = color;
    canvas.drawPath(p, paint);
    // Stroke for definition
    final stroke = Paint()
      ..color = const Color(0xFF2F3A4E)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawPath(p, stroke);
  }

  void _drawCityLabel(Canvas canvas, Size size, String text, double x, double y, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x * size.width, y * size.height));
  }

  void _drawPin(Canvas canvas, Offset c, Color color, IconData icon, String label) {
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(c, 10, shadow);
    final paint = Paint()..color = color;
    canvas.drawCircle(c, 7, paint);
    final ring = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(c, 7, ring);
  }

  void _drawPulseDot(Canvas canvas, Offset c, int tick) {
    final pulse = ((tick % 4) / 4.0);
    // Outer pulse ring
    final pulseRadius = 14 + pulse * 22;
    final pulsePaint = Paint()
      ..color = AppColors.brand.withValues(alpha: (1 - pulse) * 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(c, pulseRadius, pulsePaint);
    // Inner solid dot
    final coreShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(c, 11, coreShadow);
    final core = Paint()..color = AppColors.brand;
    canvas.drawCircle(c, 9, core);
    final ring = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(c, 9, ring);
    // Crosshair
    final cross = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(c.dx - 14, c.dy), Offset(c.dx - 6, c.dy), cross);
    canvas.drawLine(Offset(c.dx + 6, c.dy), Offset(c.dx + 14, c.dy), cross);
    canvas.drawLine(Offset(c.dx, c.dy - 14), Offset(c.dx, c.dy - 6), cross);
    canvas.drawLine(Offset(c.dx, c.dy + 6), Offset(c.dx, c.dy + 14), cross);
  }

  void _drawDashed(Canvas canvas, Path path, Color color, double width, double dash, double gap) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      bool on = true;
      while (dist < metric.length) {
        final next = math.min(dist + (on ? dash : gap), metric.length);
        if (on) {
          canvas.drawPath(metric.extractPath(dist, next), paint);
        }
        dist = next;
        on = !on;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SnapMapPainter old) =>
      old.progress != progress || old.pulseTick != pulseTick;
}

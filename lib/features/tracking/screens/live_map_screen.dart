import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../app/design_system.dart';
import '../../../core/widgets/motion.dart';

/// Full-screen iOS-Maps-style live tracking page.
///
/// The map is rendered with a **fully synthetic dark cartography painter**:
/// country borders, water, highways, sea-lanes. This guarantees a real
/// Apple-Maps look in any browser without depending on tile-server quirks.
/// On top of that, glass controls, live dashboard cards, and a draggable
/// bottom sheet with the shipment timeline.
class LiveMapScreen extends StatefulWidget {
  final String tracking;
  const LiveMapScreen({super.key, required this.tracking});
  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  bool _following = true;
  bool _showDashboard = true;
  int _zoomLevel = 6;

  // Real route: Kuala Lumpur → Singapore → Jakarta.
  static const _origin = LatLng(3.1390, 101.6869);
  static const _current = LatLng(1.3521, 103.8198);
  static const _destination = LatLng(-6.2088, 106.8456);

  static const _route = <LatLng>[
    LatLng(3.1390, 101.6869),
    LatLng(2.7400, 102.2500),
    LatLng(2.2000, 102.5500),
    LatLng(1.9000, 103.0000),
    LatLng(1.3521, 103.8198),
    LatLng(0.5000, 104.5000),
    LatLng(-1.5000, 105.0000),
    LatLng(-3.5000, 105.8000),
    LatLng(-5.0000, 106.5000),
    LatLng(-6.2088, 106.8456),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  void _zoom(double delta) =>
      setState(() => _zoomLevel = (_zoomLevel + delta).clamp(2, 18).toInt());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B10),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── The synthetic dark map — fills the entire screen ─────
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: CustomPaint(
                painter: _DarkMapPainter(
                  route: _route,
                  origin: _origin,
                  current: _current,
                  destination: _destination,
                  zoom: _zoomLevel,
                ),
              ),
            ),
          ),
          // Very light vignette (no more heavy dark overlay)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.22),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // ── Top glass bar ───────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    _GlassButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.62),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.white
                                      .withValues(alpha: 0.14)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tracking',
                                    style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 10.5,
                                        letterSpacing: 0.3)),
                                Text(widget.tracking,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GlassButton(icon: Icons.share_rounded, onTap: () {}),
                  ],
                ),
              ),
            ),
          ),
          // ── Live status pill ───────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 0,
            right: 0,
            child: const Center(child: _LiveStatusPill()),
          ),
          // ── Right-side zoom + recenter + dashboard toggle ──────
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + 200,
            child: Column(
              children: [
                _GlassButton(
                  icon: Icons.add_rounded,
                  onTap: () => _zoom(1),
                  size: 40,
                ),
                const SizedBox(height: 8),
                _GlassButton(
                  icon: Icons.remove_rounded,
                  onTap: () => _zoom(-1),
                  size: 40,
                ),
                const SizedBox(height: 8),
                _GlassButton(
                  icon: _following
                      ? Icons.gps_fixed_rounded
                      : Icons.gps_not_fixed_rounded,
                  onTap: () => setState(() => _following = !_following),
                  size: 40,
                  active: _following,
                ),
                const SizedBox(height: 8),
                _GlassButton(
                  icon: _showDashboard
                      ? Icons.dashboard_rounded
                      : Icons.dashboard_outlined,
                  onTap: () => setState(() => _showDashboard = !_showDashboard),
                  size: 40,
                  active: _showDashboard,
                ),
              ],
            ),
          ),
          // ── Live data dashboard cards ──────────────────────────
          if (_showDashboard)
            // Compact horizontal stats bar — way less obtrusive.
            Positioned(
              left: 12,
              right: 72,
              top: MediaQuery.of(context).padding.top + 102,
              child: _CompactStatsBar(),
            ),
          // ── Bottom shipment sheet ──────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomShipmentSheet(
              tracking: widget.tracking,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Synthetic dark map painter ─────────────────────────────────────

class _DarkMapPainter extends CustomPainter {
  final List<LatLng> route;
  final LatLng origin;
  final LatLng current;
  final LatLng destination;
  final int zoom;

  _DarkMapPainter({
    required this.route,
    required this.origin,
    required this.current,
    required this.destination,
    required this.zoom,
  });

  // Map view bounds: Singapore–Jakarta corridor.
  static const _boundsN = 5.5;  // top (degrees lat)
  static const _boundsS = -8.0; // bottom
  static const _boundsW = 99.0;  // left (degrees lng)
  static const _boundsE = 108.5; // right

  // Landmass polygons (simplified coastlines, lng/lat pairs).
  // We use a few hand-tuned continent outlines plus Singapore,
  // Java, Sumatra, Borneo.
  static final List<List<LatLng>> _landmasses = [
    // Malay Peninsula (Malaysia + Thailand south)
    [
      const LatLng(5.5, 101.0), const LatLng(5.0, 100.5),
      const LatLng(4.5, 100.5), const LatLng(3.8, 100.8),
      const LatLng(2.8, 101.5), const LatLng(2.0, 102.0),
      const LatLng(1.4, 103.5), const LatLng(1.2, 103.7),
      const LatLng(1.7, 104.0), const LatLng(2.4, 104.2),
      const LatLng(3.0, 103.5), const LatLng(3.6, 103.3),
      const LatLng(4.5, 103.5), const LatLng(5.2, 103.0),
      const LatLng(5.5, 102.5), const LatLng(5.5, 101.0),
    ],
    // Sumatra (long island)
    [
      const LatLng(5.5, 95.0), const LatLng(4.0, 96.0),
      const LatLng(2.5, 97.5), const LatLng(1.0, 98.5),
      const LatLng(0.0, 99.5), const LatLng(-1.0, 100.5),
      const LatLng(-2.0, 101.0), const LatLng(-3.5, 101.5),
      const LatLng(-5.0, 102.0), const LatLng(-6.0, 102.5),
      const LatLng(-5.8, 104.0), const LatLng(-4.5, 105.5),
      const LatLng(-3.0, 106.0), const LatLng(-2.0, 105.5),
      const LatLng(-0.5, 105.0), const LatLng(0.5, 104.5),
      const LatLng(1.5, 104.0), const LatLng(2.5, 102.0),
      const LatLng(3.5, 101.0), const LatLng(4.5, 100.0),
      const LatLng(5.5, 99.0), const LatLng(5.5, 95.0),
    ],
    // Java
    [
      const LatLng(-6.0, 105.0), const LatLng(-6.5, 105.5),
      const LatLng(-7.0, 106.0), const LatLng(-7.5, 106.5),
      const LatLng(-8.0, 107.0), const LatLng(-8.0, 108.0),
      const LatLng(-7.5, 109.0), const LatLng(-7.0, 110.0),
      const LatLng(-6.5, 111.0), const LatLng(-6.0, 112.0),
      const LatLng(-6.0, 114.0), const LatLng(-7.0, 114.0),
      const LatLng(-7.5, 113.0), const LatLng(-7.5, 111.5),
      const LatLng(-7.0, 110.0), const LatLng(-6.5, 108.5),
      const LatLng(-6.0, 107.5), const LatLng(-6.0, 105.0),
    ],
    // Borneo
    [
      const LatLng(7.0, 117.0), const LatLng(5.0, 118.0),
      const LatLng(3.0, 118.5), const LatLng(1.0, 118.0),
      const LatLng(-1.0, 117.0), const LatLng(-3.0, 116.0),
      const LatLng(-4.0, 114.0), const LatLng(-3.5, 112.0),
      const LatLng(-2.5, 110.0), const LatLng(-1.5, 109.5),
      const LatLng(0.0, 109.0), const LatLng(1.5, 109.0),
      const LatLng(3.0, 110.0), const LatLng(4.5, 110.5),
      const LatLng(5.5, 112.0), const LatLng(7.0, 114.0),
      const LatLng(7.0, 117.0),
    ],
    // Small islands (Riau, Bangka, Belitung)
    [
      const LatLng(0.5, 104.0), const LatLng(0.0, 105.0),
      const LatLng(-0.5, 105.5), const LatLng(-1.5, 105.0),
      const LatLng(-1.5, 104.0), const LatLng(-0.5, 103.5),
      const LatLng(0.5, 104.0),
    ],
    [
      const LatLng(-2.5, 105.0), const LatLng(-3.0, 106.0),
      const LatLng(-3.5, 106.0), const LatLng(-3.5, 105.0),
      const LatLng(-2.5, 105.0),
    ],
  ];

  // City labels and their pixel positions will be drawn on top of the map.
  static const _cities = [
    ('Kuala Lumpur', 3.139, 101.6869, 'Origin'),
    ('Singapore', 1.3521, 103.8198, 'Current'),
    ('Jakarta', -6.2088, 106.8456, 'Destination'),
    ('Johor Bahru', 1.4927, 103.7414, null),
    ('Batam', 1.0456, 104.0305, null),
    ('Palembang', -2.9761, 104.7754, null),
    ('Bandung', -6.9175, 107.6191, null),
    ('Surabaya', -7.2575, 112.7521, null),
    ('Medan', 3.5952, 98.6722, null),
    ('Pekanbaru', 0.5071, 101.4478, null),
    ('Padang', -0.9471, 100.4172, null),
  ];

  // Major highways in the region.
  static const _highways = <List<LatLng>>[
    // North-South highway on the Malay peninsula
    [LatLng(5.5, 100.5), LatLng(4.5, 101.0), LatLng(3.5, 101.5),
     LatLng(2.7, 101.9), LatLng(1.7, 103.0), LatLng(1.3, 103.7)],
    // East-West on Java
    [LatLng(-6.2, 106.8), LatLng(-6.9, 107.6), LatLng(-7.0, 110.0),
     LatLng(-7.2, 112.5)],
  ];

  // Convert lat/lng to canvas position with mercator-ish projection.
  Offset _project(LatLng p, Size size) {
    final x = (p.longitude - _boundsW) / (_boundsE - _boundsW) * size.width;
    final y = (_boundsN - p.latitude) / (_boundsN - _boundsS) * size.height;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // ── Ocean gradient base ───────────────────────────────
    final oceanRect = Offset.zero & size;
    final oceanPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, 0.3),
        radius: 1.4,
        colors: [Color(0xFF0A1F35), Color(0xFF050D1A), Color(0xFF02060F)],
        stops: [0.0, 0.7, 1.0],
      ).createShader(oceanRect);
    canvas.drawRect(oceanRect, oceanPaint);

    // ── Subtle grid lines (lat/lng) ──────────────────────
    final gridPaint = Paint()
      ..color = const Color(0xFF1A3A5C).withValues(alpha: 0.18)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (var lng = 100.0; lng <= 108.0; lng += 2) {
      final x = (lng - _boundsW) / (_boundsE - _boundsW) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var lat = 5.0; lat >= -7.0; lat -= 2) {
      final y = (_boundsN - lat) / (_boundsN - _boundsS) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // ── Landmasses ────────────────────────────────────────
    final landPaint = Paint()
      ..color = const Color(0xFF1B2838)
      ..style = PaintingStyle.fill;
    final landStroke = Paint()
      ..color = const Color(0xFF2A4A6C)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (final land in _landmasses) {
      final path = ui.Path();
      final pts = land.map((p) => _project(p, size)).toList();
      path.moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, landPaint);
      canvas.drawPath(path, landStroke);
    }

    // ── Highways ──────────────────────────────────────────
    final highwayPaint = Paint()
      ..color = const Color(0xFFFFC845).withValues(alpha: 0.35)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final hwy in _highways) {
      final path = ui.Path();
      final pts = hwy.map((p) => _project(p, size)).toList();
      path.moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, highwayPaint);
    }

    // ── Compass rose (top right corner) ──────────────────
    _drawCompass(canvas, Offset(size.width - 50, 60));

    // ── Scale bar (bottom left) ──────────────────────────
    _drawScaleBar(canvas, Offset(20, size.height - 240), size);

    // ── Route line — glow halo + bright centre ───────────
    final routePoints = route.map((p) => _project(p, size)).toList();
    final routePath = ui.Path();
    routePath.moveTo(routePoints.first.dx, routePoints.first.dy);
    for (final p in routePoints.skip(1)) {
      routePath.lineTo(p.dx, p.dy);
    }

    final routeHalo = Paint()
      ..color = const Color(0xFFFF453A).withValues(alpha: 0.30)
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(routePath, routeHalo);

    final routeLine = Paint()
      ..color = const Color(0xFFFF453A)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(routePath, routeLine);

    // Animated dashed overlay (drawn fresh — animation tick on repaint).
    // The painter doesn't run an animation but we draw a subtle dash pattern.
    final routeDash = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < routePoints.length - 1; i++) {
      final p1 = routePoints[i];
      final p2 = routePoints[i + 1];
      // Draw short white tick every 60px along route
      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      final ux = dx / dist;
      final uy = dy / dist;
      // Perpendicular for tick
      final px = -uy;
      final py = ux;
      for (var t = 0.0; t < dist; t += 24) {
        final cx = p1.dx + ux * t;
        final cy = p1.dy + uy * t;
        canvas.drawLine(
          Offset(cx + px * 6, cy + py * 6),
          Offset(cx - px * 6, cy - py * 6),
          routeDash,
        );
      }
    }

    // ── City labels ──────────────────────────────────────
    for (final city in _cities) {
      final p = _project(LatLng(city.$2, city.$3), size);
      // Label dot
      final isKey = city.$4 != null;
      final dotColor = isKey
          ? (city.$4 == 'Origin'
              ? const Color(0xFF10B981)
              : city.$4 == 'Current'
                  ? const Color(0xFFFF453A)
                  : const Color(0xFF60A5FA))
          : const Color(0xFF7C8A9A);
      final dotSize = isKey ? 5.0 : 3.0;
      canvas.drawCircle(
          p, dotSize, Paint()..color = dotColor.withValues(alpha: 0.4));
      canvas.drawCircle(p, dotSize * 0.55, Paint()..color = dotColor);

      // Label text
      final tp = TextPainter(
        text: TextSpan(
          text: city.$1,
          style: TextStyle(
            color: isKey ? Colors.white : const Color(0xFF9AB0C5),
            fontSize: isKey ? 11 : 9,
            fontWeight: isKey ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final lx = p.dx + 7;
      final ly = p.dy - tp.height / 2;
      // Halo
      tp.paint(canvas, Offset(lx, ly));
    }

    // ── Origin marker (green warehouse) ──────────────────
    _drawMarker(
      canvas,
      _project(origin, size),
      const Color(0xFF10B981),
      Icons.warehouse_rounded,
      isKey: true,
    );

    // ── Current position marker (red pulse — static
    //    representation, the animation runs in the Stack) ─
    _drawCurrentMarker(canvas, _project(current, size));

    // ── Destination marker (white/blue location pin) ────
    _drawMarker(
      canvas,
      _project(destination, size),
      const Color(0xFF60A5FA),
      Icons.location_on_rounded,
      isKey: true,
    );
  }

  void _drawCurrentMarker(Canvas canvas, Offset p) {
    // Outer halo
    canvas.drawCircle(
        p,
        22,
        Paint()
          ..color = const Color(0xFFFF453A).withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    // Mid ring
    canvas.drawCircle(p, 14,
        Paint()..color = const Color(0xFFFF453A).withValues(alpha: 0.45));
    // Truck body
    canvas.drawCircle(p, 9, Paint()..color = const Color(0xFFFF453A));
    canvas.drawCircle(
        p,
        9,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke);
    // Truck icon
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.local_shipping_rounded.codePoint),
        style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontFamily: Icons.local_shipping_rounded.fontFamily,
            package: Icons.local_shipping_rounded.fontPackage),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
  }

  void _drawCompass(Canvas canvas, Offset center) {
    final p = Paint()
      ..color = const Color(0xFF1B2838).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFF2A4A6C)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 22, p);
    canvas.drawCircle(center, 22, stroke);
    // N arrow
    final tp = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - 18));
    // South dot
    canvas.drawCircle(Offset(center.dx, center.dy + 14),
        1.5, Paint()..color = const Color(0xFF7C8A9A));
  }

  void _drawScaleBar(Canvas canvas, Offset pos, Size size) {
    final barWidth = 80.0;
    final p = Paint()..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawLine(pos, Offset(pos.dx + barWidth, pos.dy),
        p..strokeWidth = 2);
    // 100 km at zoom 5 ≈ 80px
    final tp = TextPainter(
      text: TextSpan(
        text: '100 km',
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 9,
            fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx, pos.dy - 14));
  }

  void _drawMarker(Canvas canvas, Offset p, Color color, IconData icon,
      {bool isKey = false}) {
    if (!isKey) return;
    final outerR = isKey ? 14.0 : 10.0;
    final innerR = isKey ? 9.0 : 6.0;
    canvas.drawCircle(
        p,
        outerR,
        Paint()
          ..color = color.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(p, outerR * 0.7, Paint()..color = color);
    canvas.drawCircle(p, outerR * 0.7,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);

    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: Colors.white,
          fontSize: isKey ? 10 : 8,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DarkMapPainter oldDelegate) =>
      oldDelegate.zoom != zoom;
}

// ── Pulse pin (animated, current position) ────────────────────────

class _PulsePin extends StatefulWidget {
  final Offset position;
  const _PulsePin({required this.position});
  @override
  State<_PulsePin> createState() => _PulsePinState();
}

class _PulsePinState extends State<_PulsePin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return CustomPaint(
          size: const Size(80, 80),
          painter: _PulsePinPainter(progress: _c.value),
        );
      },
    );
  }
}

class _PulsePinPainter extends CustomPainter {
  final double progress;
  _PulsePinPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Pulse rings
    for (var i = 0; i < 3; i++) {
      final t = ((progress + i / 3) % 1.0);
      final r = 10 + t * 30;
      final p = Paint()
        ..color = const Color(0xFFFF453A).withValues(alpha: 0.45 * (1 - t))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, r, p);
    }
    // Truck body
    final body = Paint()..color = const Color(0xFFFF453A);
    canvas.drawCircle(center, 11, body);
    canvas.drawCircle(
        center, 11, Paint()..color = Colors.white..strokeWidth = 2.5..style = PaintingStyle.stroke);
    // Truck icon
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.local_shipping_rounded.codePoint),
        style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: Icons.local_shipping_rounded.fontFamily,
            package: Icons.local_shipping_rounded.fontPackage),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PulsePinPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Glass primitives ──────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool active;
  const _GlassButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.active = false,
  });
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? AppColors.brand
                    : Colors.black.withValues(alpha: 0.50),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20), width: 0.6),
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: AppColors.brand.withValues(alpha: 0.5),
                            blurRadius: 14,
                            spreadRadius: 1),
                      ]
                    : null,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveStatusPill extends StatelessWidget {
  const _LiveStatusPill();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
              color: AppColors.success.withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: 1),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          const Text('LIVE · Last update 2s ago',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

class _CompactStatsBar extends StatelessWidget {
  const _CompactStatsBar();
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: const [
              _StatPill(label: 'ETA', value: '5:42', color: Color(0xFFFFD60A)),
              _StatDivider(),
              _StatPill(label: 'DIST', value: '12.4km', color: Color(0xFF0A84FF)),
              _StatDivider(),
              _StatPill(label: 'SPEED', value: '38km/h', color: Color(0xFF30D158)),
              _StatDivider(),
              _StatPill(label: 'BAT', value: '87%', color: Color(0xFF30D158)),
              _StatDivider(),
              _StatPill(label: 'ALT', value: '42m', color: AppColors.brand),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.12),
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 8.5,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveDashboard extends StatelessWidget {
  final String tracking;
  const _LiveDashboard({required this.tracking});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.info,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text('Out for delivery',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800)),
              ),
              const Spacer(),
              const Icon(Icons.refresh_rounded,
                  color: Colors.white60, size: 14),
              const SizedBox(width: 4),
              const Text('2s',
                  style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              _DashboardCell(
                  label: 'ETA',
                  value: '5:42',
                  sub: 'PM',
                  color: AppColors.warning),
              SizedBox(width: 8),
              _DashboardCell(
                  label: 'Distance',
                  value: '12.4',
                  sub: 'km',
                  color: AppColors.info),
              SizedBox(width: 8),
              _DashboardCell(
                  label: 'Speed',
                  value: '38',
                  sub: 'km/h',
                  color: AppColors.success),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              _DashboardCell(
                  label: 'Altitude',
                  value: '42',
                  sub: 'm',
                  color: AppColors.accent),
              SizedBox(width: 8),
              _DashboardCell(
                  label: 'Bearing',
                  value: 'NE',
                  sub: '37°',
                  color: AppColors.warning),
              SizedBox(width: 8),
              _DashboardCell(
                  label: 'Battery',
                  value: '87',
                  sub: '%',
                  color: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardCell extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  const _DashboardCell({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 9.5,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(sub,
                      style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomShipmentSheet extends StatefulWidget {
  final String tracking;
  const _BottomShipmentSheet({required this.tracking});
  @override
  State<_BottomShipmentSheet> createState() => _BottomShipmentSheetState();
}

class _BottomShipmentSheetState extends State<_BottomShipmentSheet> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final t = widget.tracking;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: _expanded ? 0.92 : 0.78),
          ],
          stops: const [0.0, 0.18],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          0, 12, 0, MediaQuery.of(context).padding.bottom + 8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: EdgeInsets.all(_expanded ? 16 : 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _expanded ? 0.08 : 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tap-to-expand header
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Shipment ${t.substring(0, 12)}…',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3)),
                            const SizedBox(height: 2),
                            const Text('Petaling Jaya · 6.2 km from you',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 11.5)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text('On time',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(Icons.expand_more_rounded,
                            color: Colors.white60, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 14),
              const _MiniTimeline(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SheetAction(
                      icon: Icons.phone_rounded,
                      label: 'Call driver',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SheetAction(
                      icon: Icons.notifications_active_rounded,
                      label: 'Notify me',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SheetAction(
                      icon: Icons.share_rounded,
                      label: 'Share',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniTimeline extends StatelessWidget {
  const _MiniTimeline();
  @override
  Widget build(BuildContext context) {
    final events = [
      ('Out for delivery', '3:42 PM', AppColors.success),
      ('Arrived at hub', '11:15 AM', AppColors.success),
      ('In transit', 'Jul 2', AppColors.success),
      ('Picked up', 'Jul 1', AppColors.success),
      ('Created', 'Jun 30', AppColors.success),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < events.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                        color: events[i].$3, shape: BoxShape.circle),
                  ),
                  if (i < events.length - 1)
                    Container(
                      width: 1.5,
                      height: 22,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(events[i].$1,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(events[i].$2,
                          style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SheetAction(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

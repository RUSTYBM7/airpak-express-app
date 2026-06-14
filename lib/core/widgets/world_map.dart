import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/design_system.dart';

/// Lightweight world-map painter.
///
/// Uses an equirectangular projection so any (lat, lng) pair maps
/// to a deterministic canvas coordinate. We don't try to be a
/// faithful political map — we paint rough continental outlines
/// that cover the populated landmasses well enough to look like a
/// real shipping-world map. All shapes are normalized 0..1 so the
/// painter works at any canvas size.
///
/// Country outlines are derived from simplified GeoJSON-ish polygon
/// data (each polygon is a list of [lng, lat] pairs normalized to
/// 0..1 against [-180, 180] longitude and [-90, 90] latitude).
class WorldMapPainter extends CustomPainter {
  final double progress;       // 0..1, courier position along route
  final double? holdProgress;  // 0..1, optional hold point
  final List<GeoPoint> route;  // origin → waypoints → destination
  final List<GeoPoint> courierPath; // sub-route for the current progress
  final int pulseTick;         // animation frame
  final Color landColor;
  final Color strokeColor;
  final Color gridColor;
  final Color routeColor;
  final Color courierColor;
  final Color labelColor;
  final bool showLabels;

  WorldMapPainter({
    required this.progress,
    this.holdProgress,
    required this.route,
    required this.courierPath,
    required this.pulseTick,
    required this.landColor,
    required this.strokeColor,
    required this.gridColor,
    required this.routeColor,
    required this.courierColor,
    required this.labelColor,
    this.showLabels = true,
  });

  /// Convert a (lat, lng) to canvas coordinates. Equirectangular.
  static Offset project(GeoPoint p, Size size) {
    // Longitude: -180..180 → 0..width
    final x = (p.lng + 180) / 360 * size.width;
    // Latitude: 90..-90 → 0..height (flipped)
    final y = (90 - p.lat) / 180 * size.height;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintGraticule(canvas, size);
    _paintLand(canvas, size);
    _paintRoute(canvas, size);
    _paintEndpoints(canvas, size);
    _paintHoldMarker(canvas, size);
    _paintCourier(canvas, size);
    if (showLabels) _paintLabels(canvas, size);
    _paintCompass(canvas, size);
    _paintScaleBar(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0A0F1C);
    canvas.drawRect(Offset.zero & size, bg);
    // Subtle ocean gradient
    final ocean = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0A0F1C), Color(0xFF131A2D), Color(0xFF0A0F1C)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, ocean);
  }

  void _paintGraticule(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    // Vertical lines (every 30° longitude)
    for (int lng = -180; lng <= 180; lng += 30) {
      final x = (lng + 180) / 360 * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    // Horizontal lines (every 30° latitude)
    for (int lat = -90; lat <= 90; lat += 30) {
      final y = (90 - lat) / 180 * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    // Equator & prime meridian — bolder
    final bold = Paint()
      ..color = gridColor.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    final eq = (90 - 0) / 180 * size.height;
    canvas.drawLine(Offset(0, eq), Offset(size.width, eq), bold);
    final pm = (0 + 180) / 360 * size.width;
    canvas.drawLine(Offset(pm, 0), Offset(pm, size.height), bold);
  }

  void _paintLand(Canvas canvas, Size size) {
    // Paint each continent outline
    for (final polygon in _continents) {
      _paintPolygon(canvas, size, polygon, landColor, strokeColor);
    }
    // Subtle highlight for major regions
    final highlight = Paint()..color = landColor.withValues(alpha: 0.15);
    for (final region in _regionHighlights) {
      _paintPolygon(canvas, size, region, landColor.withValues(alpha: 0.10), strokeColor.withValues(alpha: 0.4));
    }
  }

  void _paintPolygon(Canvas canvas, Size size, List<GeoPoint> points, Color fill, Color stroke) {
    if (points.isEmpty) return;
    final path = Path();
    final first = project(points.first, size);
    path.moveTo(first.dx, first.dy);
    for (int i = 1; i < points.length; i++) {
      final p = project(points[i], size);
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    final fillPaint = Paint()..color = fill;
    canvas.drawPath(path, fillPaint);
    final strokePaint = Paint()
      ..color = stroke
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);
  }

  void _paintRoute(Canvas canvas, Size size) {
    if (route.length < 2) return;
    // Background full route (faint)
    final fullPath = Path();
    final first = project(route.first, size);
    fullPath.moveTo(first.dx, first.dy);
    for (int i = 1; i < route.length; i++) {
      final p = project(route[i], size);
      fullPath.lineTo(p.dx, p.dy);
    }
    final grey = Paint()
      ..color = const Color(0xFF3B475E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fullPath, grey);

    // Active route (gradient) — up to courier position
    if (courierPath.length >= 2) {
      final active = Path();
      final cf = project(courierPath.first, size);
      active.moveTo(cf.dx, cf.dy);
      for (int i = 1; i < courierPath.length; i++) {
        final p = project(courierPath[i], size);
        active.lineTo(p.dx, p.dy);
      }
      final activePaint = Paint()
        ..shader = const SweepGradient(
          colors: [AppColors.brand, Color(0xFFEF4444), AppColors.warning, AppColors.brand],
        ).createShader(Rect.fromPoints(first, project(route.last, size)))
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(active, activePaint);
    }
  }

  void _paintEndpoints(Canvas canvas, Size size) {
    if (route.isEmpty) return;
    _paintPin(canvas, size, route.first, const Color(0xFF22C55E), Icons.circle_rounded);
    _paintPin(canvas, size, route.last, const Color(0xFFEF4444), Icons.location_on_rounded);
  }

  void _paintPin(Canvas canvas, Size size, GeoPoint p, Color color, IconData icon) {
    final c = project(p, size);
    // Shadow
    canvas.drawCircle(c, 12, Paint()..color = Colors.black.withValues(alpha: 0.45)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    // Body
    canvas.drawCircle(c, 8, Paint()..color = color);
    // Ring
    canvas.drawCircle(c, 8, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
    // Inner dot
    canvas.drawCircle(c, 3, Paint()..color = Colors.white);
  }

  void _paintHoldMarker(Canvas canvas, Size size) {
    if (holdProgress == null) return;
    if (route.length < 2) return;
    final pos = _interpolate(route, holdProgress!);
    final c = project(pos, size);
    // Warning ring
    canvas.drawCircle(c, 18, Paint()..color = AppColors.warning.withValues(alpha: 0.30));
    canvas.drawCircle(c, 14, Paint()..color = AppColors.warning.withValues(alpha: 0.55));
    // Warning triangle
    final path = Path();
    path.moveTo(c.dx, c.dy - 9);
    path.lineTo(c.dx - 9, c.dy + 7);
    path.lineTo(c.dx + 9, c.dy + 7);
    path.close();
    canvas.drawPath(path, Paint()..color = AppColors.warning);
    canvas.drawPath(path, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
    // Exclamation mark
    final tp = TextPainter(
      text: const TextSpan(text: '!', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy + 1));
  }

  void _paintCourier(Canvas canvas, Size size) {
    if (route.length < 2) return;
    final pos = _interpolate(route, progress);
    final c = project(pos, size);
    // Pulse
    final pulse = ((pulseTick % 4) / 4.0);
    canvas.drawCircle(c, 16 + pulse * 26, Paint()..color = AppColors.brand.withValues(alpha: (1 - pulse) * 0.5));
    canvas.drawCircle(c, 12 + pulse * 12, Paint()..color = AppColors.brand.withValues(alpha: (1 - pulse) * 0.35));
    // Shadow
    canvas.drawCircle(c, 11, Paint()..color = Colors.black.withValues(alpha: 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    // Core
    canvas.drawCircle(c, 9, Paint()..color = AppColors.brand);
    // Ring
    canvas.drawCircle(c, 9, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.5);
    // Crosshair
    final cross = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(c.dx - 16, c.dy), Offset(c.dx - 7, c.dy), cross);
    canvas.drawLine(Offset(c.dx + 7, c.dy), Offset(c.dx + 16, c.dy), cross);
    canvas.drawLine(Offset(c.dx, c.dy - 16), Offset(c.dx, c.dy - 7), cross);
    canvas.drawLine(Offset(c.dx, c.dy + 7), Offset(c.dx, c.dy + 16), cross);
  }

  void _paintLabels(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final city in _majorCities) {
      final p = project(GeoPoint(city.lat, city.lng), size);
      // Skip if outside canvas
      if (p.dx < 0 || p.dx > size.width || p.dy < 0 || p.dy > size.height) continue;
      tp.text = TextSpan(
        text: city.name,
        style: TextStyle(
          color: labelColor,
          fontSize: city.size ?? 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      );
      tp.layout();
      tp.paint(canvas, p + const Offset(4, -3));
    }
  }

  void _paintCompass(Canvas canvas, Size size) {
    final cx = size.width - 50.0;
    final cy = 50.0;
    final r = 22.0;
    // Outer ring
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Colors.black.withValues(alpha: 0.55));
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Colors.white.withValues(alpha: 0.2)..style = PaintingStyle.stroke..strokeWidth = 1);
    // N marker
    final tp = TextPainter(
      text: const TextSpan(text: 'N', style: TextStyle(color: AppColors.brand, fontSize: 11, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - r + 2));
    // Needle
    final needle = Path();
    needle.moveTo(cx, cy - r * 0.65);
    needle.lineTo(cx - 4, cy);
    needle.lineTo(cx + 4, cy);
    needle.close();
    canvas.drawPath(needle, Paint()..color = AppColors.brand);
    needle.reset();
    needle.moveTo(cx, cy + r * 0.65);
    needle.lineTo(cx - 4, cy);
    needle.lineTo(cx + 4, cy);
    needle.close();
    canvas.drawPath(needle, Paint()..color = Colors.white);
  }

  void _paintScaleBar(Canvas canvas, Size size) {
    final left = 16.0;
    final bottom = size.height - 18.0;
    const barWidth = 80.0; // represents 2,000 km
    // Bg
    canvas.drawRect(Rect.fromLTWH(left, bottom, barWidth, 4), Paint()..color = Colors.black.withValues(alpha: 0.55));
    // Alternating
    canvas.drawRect(Rect.fromLTWH(left, bottom, barWidth / 2, 4), Paint()..color = Colors.white);
    // Label
    final tp = TextPainter(
      text: const TextSpan(text: '2,000 km', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(left, bottom - 12));
  }

  /// Interpolate along the route at a given t (0..1).
  GeoPoint _interpolate(List<GeoPoint> pts, double t) {
    if (pts.length < 2) return pts.first;
    final clamped = t.clamp(0.0, 1.0);
    // Sum total great-circle distance, then find the segment
    final distances = <double>[];
    var total = 0.0;
    for (int i = 0; i < pts.length - 1; i++) {
      final d = _haversine(pts[i], pts[i + 1]);
      distances.add(d);
      total += d;
    }
    var target = total * clamped;
    for (int i = 0; i < distances.length; i++) {
      if (target <= distances[i]) {
        final f = distances[i] == 0 ? 0.0 : target / distances[i];
        final a = pts[i];
        final b = pts[i + 1];
        return GeoPoint(
          a.lat + (b.lat - a.lat) * f,
          a.lng + (b.lng - a.lng) * f,
        );
      }
      target -= distances[i];
    }
    return pts.last;
  }

  static double _haversine(GeoPoint a, GeoPoint b) {
    const R = 6371.0;
    final dLat = (b.lat - a.lat) * math.pi / 180;
    final dLng = (b.lng - a.lng) * math.pi / 180;
    final lat1 = a.lat * math.pi / 180;
    final lat2 = b.lat * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLng / 2) * math.sin(dLng / 2) * math.cos(lat1) * math.cos(lat2);
    return 2 * R * math.asin(math.sqrt(h));
  }

  @override
  bool shouldRepaint(covariant WorldMapPainter old) =>
      old.progress != progress ||
      old.holdProgress != holdProgress ||
      old.pulseTick != pulseTick ||
      old.route != route;
}

/// A single geographic point in lat/lng space.
class GeoPoint {
  final double lat;
  final double lng;
  final String? label;
  const GeoPoint(this.lat, this.lng, {this.label});
  @override
  bool operator ==(Object other) => other is GeoPoint && other.lat == lat && other.lng == lng;
  @override
  int get hashCode => Object.hash(lat, lng);
}

class _City extends GeoPoint {
  final String name;
  final double? size;
  const _City(super.lat, super.lng, this.name, {this.size});
}

// ── Data: simplified continent outlines ──────────────────────────────
//
// Coordinates are real (lat, lng). The painter projects them to
// canvas via equirectangular projection. These polygons are NOT
// politically accurate — they cover the populated landmasses well
// enough to look like a world map.

const List<List<GeoPoint>> _continents = [
  // North America
  [
    GeoPoint(71, -156), GeoPoint(70, -141), GeoPoint(70, -130), GeoPoint(60, -141),
    GeoPoint(60, -135), GeoPoint(55, -132), GeoPoint(50, -125), GeoPoint(45, -124),
    GeoPoint(40, -124), GeoPoint(32, -117), GeoPoint(28, -113), GeoPoint(25, -110),
    GeoPoint(22, -105), GeoPoint(18, -103), GeoPoint(16, -97), GeoPoint(15, -92),
    GeoPoint(16, -88), GeoPoint(19, -87), GeoPoint(21, -86), GeoPoint(18, -81),
    GeoPoint(15, -78), GeoPoint(11, -83), GeoPoint(9, -77), GeoPoint(7, -77),
    GeoPoint(7, -81), GeoPoint(8, -78), GeoPoint(8, -77), GeoPoint(11, -75),
    GeoPoint(12, -72), GeoPoint(11, -64), GeoPoint(10, -62), GeoPoint(8, -60),
    GeoPoint(5, -52), GeoPoint(1, -49), GeoPoint(-2, -44), GeoPoint(-8, -35),
    GeoPoint(-12, -38), GeoPoint(-22, -41), GeoPoint(-23, -43), GeoPoint(-30, -50),
    GeoPoint(-32, -52), GeoPoint(-38, -57), GeoPoint(-42, -64), GeoPoint(-50, -68),
    GeoPoint(-52, -67), GeoPoint(-55, -65), GeoPoint(-55, -63), GeoPoint(-50, -60),
    GeoPoint(-45, -60), GeoPoint(-40, -60), GeoPoint(-40, -75), GeoPoint(-50, -75),
    GeoPoint(-55, -78), GeoPoint(-65, -78), GeoPoint(-72, -78), GeoPoint(-75, -90),
    GeoPoint(-78, -100), GeoPoint(-80, -110), GeoPoint(-75, -120), GeoPoint(-72, -125),
    GeoPoint(-68, -130), GeoPoint(-65, -135), GeoPoint(-60, -140), GeoPoint(-58, -135),
    GeoPoint(-55, -132), GeoPoint(-58, -135), GeoPoint(-55, -132), GeoPoint(60, -141),
    GeoPoint(60, -150), GeoPoint(60, -160), GeoPoint(65, -165), GeoPoint(70, -160),
  ],
  // South America
  [
    GeoPoint(12, -71), GeoPoint(10, -75), GeoPoint(8, -77), GeoPoint(5, -78),
    GeoPoint(1, -80), GeoPoint(-3, -80), GeoPoint(-5, -78), GeoPoint(-10, -78),
    GeoPoint(-15, -76), GeoPoint(-20, -72), GeoPoint(-25, -70), GeoPoint(-30, -71),
    GeoPoint(-35, -72), GeoPoint(-40, -73), GeoPoint(-45, -75), GeoPoint(-50, -74),
    GeoPoint(-55, -68), GeoPoint(-55, -65), GeoPoint(-52, -67), GeoPoint(-50, -68),
    GeoPoint(-45, -65), GeoPoint(-40, -62), GeoPoint(-35, -57), GeoPoint(-32, -52),
    GeoPoint(-30, -50), GeoPoint(-25, -48), GeoPoint(-22, -42), GeoPoint(-20, -40),
    GeoPoint(-15, -39), GeoPoint(-10, -37), GeoPoint(-5, -35), GeoPoint(0, -50),
    GeoPoint(5, -52), GeoPoint(8, -60), GeoPoint(10, -62), GeoPoint(11, -64),
    GeoPoint(12, -67), GeoPoint(12, -71),
  ],
  // Greenland
  [
    GeoPoint(83, -30), GeoPoint(82, -15), GeoPoint(78, -20), GeoPoint(75, -20),
    GeoPoint(72, -25), GeoPoint(68, -30), GeoPoint(63, -42), GeoPoint(60, -45),
    GeoPoint(65, -50), GeoPoint(70, -55), GeoPoint(76, -65), GeoPoint(80, -70),
    GeoPoint(82, -50), GeoPoint(83, -30),
  ],
  // Europe
  [
    GeoPoint(71, 30), GeoPoint(70, 22), GeoPoint(68, 15), GeoPoint(65, 12),
    GeoPoint(62, 5), GeoPoint(58, 5), GeoPoint(55, 8), GeoPoint(54, 11),
    GeoPoint(54, 14), GeoPoint(50, 16), GeoPoint(48, 17), GeoPoint(46, 15),
    GeoPoint(44, 14), GeoPoint(42, 12), GeoPoint(40, 15), GeoPoint(38, 16),
    GeoPoint(37, 15), GeoPoint(38, 12), GeoPoint(40, 10), GeoPoint(42, 7),
    GeoPoint(43, 5), GeoPoint(43, 3), GeoPoint(41, 0), GeoPoint(40, -2),
    GeoPoint(37, -6), GeoPoint(36, -6), GeoPoint(37, -9), GeoPoint(38, -10),
    GeoPoint(40, -10), GeoPoint(42, -9), GeoPoint(44, -5), GeoPoint(46, -2),
    GeoPoint(48, -1), GeoPoint(50, -5), GeoPoint(51, -3), GeoPoint(55, 0),
    GeoPoint(58, 0), GeoPoint(60, 5), GeoPoint(65, 12),
  ],
  // Africa
  [
    GeoPoint(37, -7), GeoPoint(36, -10), GeoPoint(35, -10), GeoPoint(32, -9),
    GeoPoint(30, -7), GeoPoint(28, -10), GeoPoint(25, -15), GeoPoint(22, -17),
    GeoPoint(20, -16), GeoPoint(17, -14), GeoPoint(15, -12), GeoPoint(13, -10),
    GeoPoint(11, -8), GeoPoint(8, -5), GeoPoint(5, 0), GeoPoint(0, 5),
    GeoPoint(-5, 12), GeoPoint(-10, 15), GeoPoint(-15, 12), GeoPoint(-18, 11),
    GeoPoint(-22, 14), GeoPoint(-25, 15), GeoPoint(-28, 16), GeoPoint(-32, 18),
    GeoPoint(-34, 20), GeoPoint(-35, 22), GeoPoint(-30, 30), GeoPoint(-25, 33),
    GeoPoint(-20, 35), GeoPoint(-15, 38), GeoPoint(-10, 40), GeoPoint(-5, 42),
    GeoPoint(0, 42), GeoPoint(5, 40), GeoPoint(10, 38), GeoPoint(12, 36),
    GeoPoint(14, 32), GeoPoint(16, 30), GeoPoint(20, 28), GeoPoint(24, 22),
    GeoPoint(28, 20), GeoPoint(30, 22), GeoPoint(32, 25), GeoPoint(33, 28),
    GeoPoint(34, 30), GeoPoint(36, 32), GeoPoint(37, 30), GeoPoint(37, -7),
  ],
  // Asia (mainland + India + SE Asia)
  [
    GeoPoint(70, 60), GeoPoint(75, 70), GeoPoint(78, 75), GeoPoint(75, 90),
    GeoPoint(72, 100), GeoPoint(70, 110), GeoPoint(68, 120), GeoPoint(65, 130),
    GeoPoint(62, 140), GeoPoint(58, 145), GeoPoint(55, 142), GeoPoint(50, 142),
    GeoPoint(48, 140), GeoPoint(45, 135), GeoPoint(40, 132), GeoPoint(35, 130),
    GeoPoint(30, 122), GeoPoint(28, 118), GeoPoint(24, 115), GeoPoint(20, 110),
    GeoPoint(18, 108), GeoPoint(15, 108), GeoPoint(12, 109), GeoPoint(10, 108),
    GeoPoint(8, 105), GeoPoint(5, 103), GeoPoint(2, 105), GeoPoint(0, 107),
    GeoPoint(-2, 108), GeoPoint(-5, 110), GeoPoint(-7, 115), GeoPoint(-8, 116),
    GeoPoint(-7, 117), GeoPoint(-3, 118), GeoPoint(0, 117), GeoPoint(2, 113),
    GeoPoint(5, 112), GeoPoint(8, 105),
  ],
  // Indian subcontinent
  [
    GeoPoint(35, 75), GeoPoint(33, 78), GeoPoint(30, 80), GeoPoint(28, 83),
    GeoPoint(25, 85), GeoPoint(22, 88), GeoPoint(20, 88), GeoPoint(18, 85),
    GeoPoint(15, 82), GeoPoint(12, 80), GeoPoint(10, 78), GeoPoint(8, 77),
    GeoPoint(8, 80), GeoPoint(10, 82), GeoPoint(15, 82), GeoPoint(20, 85),
    GeoPoint(22, 88), GeoPoint(25, 85), GeoPoint(28, 83), GeoPoint(30, 80),
    GeoPoint(33, 78), GeoPoint(35, 75),
  ],
  // Middle East / Arabia
  [
    GeoPoint(35, 38), GeoPoint(33, 40), GeoPoint(30, 42), GeoPoint(27, 45),
    GeoPoint(24, 48), GeoPoint(22, 52), GeoPoint(20, 55), GeoPoint(17, 55),
    GeoPoint(14, 50), GeoPoint(12, 45), GeoPoint(13, 43), GeoPoint(15, 42),
    GeoPoint(20, 40), GeoPoint(24, 38), GeoPoint(28, 36), GeoPoint(32, 35),
    GeoPoint(35, 38),
  ],
  // Australia
  [
    GeoPoint(-12, 130), GeoPoint(-10, 135), GeoPoint(-12, 137), GeoPoint(-15, 138),
    GeoPoint(-18, 140), GeoPoint(-22, 142), GeoPoint(-25, 145), GeoPoint(-30, 150),
    GeoPoint(-35, 150), GeoPoint(-37, 145), GeoPoint(-38, 140), GeoPoint(-36, 137),
    GeoPoint(-35, 135), GeoPoint(-32, 130), GeoPoint(-30, 125), GeoPoint(-25, 115),
    GeoPoint(-22, 115), GeoPoint(-20, 118), GeoPoint(-15, 125), GeoPoint(-12, 130),
  ],
  // New Zealand
  [
    GeoPoint(-35, 175), GeoPoint(-37, 178), GeoPoint(-40, 177), GeoPoint(-42, 174),
    GeoPoint(-45, 170), GeoPoint(-46, 170), GeoPoint(-44, 172), GeoPoint(-42, 174),
    GeoPoint(-40, 177), GeoPoint(-37, 178), GeoPoint(-35, 175),
  ],
  // Antarctica (rough)
  [
    GeoPoint(-65, -180), GeoPoint(-70, -150), GeoPoint(-72, -120), GeoPoint(-75, -90),
    GeoPoint(-78, -60), GeoPoint(-72, -30), GeoPoint(-68, 0), GeoPoint(-70, 30),
    GeoPoint(-72, 60), GeoPoint(-70, 90), GeoPoint(-66, 120), GeoPoint(-68, 150),
    GeoPoint(-72, 180), GeoPoint(-65, 180),
  ],
  // Iceland
  [
    GeoPoint(66, -24), GeoPoint(64, -22), GeoPoint(63, -19), GeoPoint(64, -14),
    GeoPoint(66, -14), GeoPoint(67, -18), GeoPoint(66, -24),
  ],
  // Indonesia (rough)
  [
    GeoPoint(5, 95), GeoPoint(2, 98), GeoPoint(-2, 100), GeoPoint(-5, 103),
    GeoPoint(-7, 107), GeoPoint(-8, 112), GeoPoint(-7, 114), GeoPoint(-5, 114),
    GeoPoint(-2, 110), GeoPoint(0, 105), GeoPoint(2, 100), GeoPoint(5, 95),
  ],
  // Japan
  [
    GeoPoint(45, 142), GeoPoint(43, 145), GeoPoint(40, 142), GeoPoint(36, 140),
    GeoPoint(34, 138), GeoPoint(32, 132), GeoPoint(33, 130), GeoPoint(35, 132),
    GeoPoint(38, 138), GeoPoint(40, 142), GeoPoint(45, 142),
  ],
  // UK
  [
    GeoPoint(58, -5), GeoPoint(57, -2), GeoPoint(55, 1), GeoPoint(52, 2),
    GeoPoint(50, -1), GeoPoint(50, -5), GeoPoint(53, -8), GeoPoint(55, -7),
    GeoPoint(58, -5),
  ],
  // Madagascar
  [
    GeoPoint(-12, 49), GeoPoint(-15, 50), GeoPoint(-20, 47), GeoPoint(-25, 45),
    GeoPoint(-25, 43), GeoPoint(-22, 43), GeoPoint(-18, 44), GeoPoint(-14, 47),
    GeoPoint(-12, 49),
  ],
  // New Guinea
  [
    GeoPoint(-1, 131), GeoPoint(-3, 135), GeoPoint(-7, 140), GeoPoint(-10, 145),
    GeoPoint(-8, 150), GeoPoint(-5, 148), GeoPoint(-3, 144), GeoPoint(-1, 140),
    GeoPoint(0, 135), GeoPoint(-1, 131),
  ],
];

const List<List<GeoPoint>> _regionHighlights = [
  // North America highlight
  [
    GeoPoint(40, -100), GeoPoint(45, -90), GeoPoint(40, -75), GeoPoint(30, -85),
    GeoPoint(25, -100), GeoPoint(30, -110), GeoPoint(40, -120), GeoPoint(45, -110),
  ],
  // Europe highlight
  [
    GeoPoint(55, 10), GeoPoint(55, 30), GeoPoint(45, 30), GeoPoint(40, 15),
    GeoPoint(45, 5), GeoPoint(55, 0), GeoPoint(58, 5), GeoPoint(55, 10),
  ],
  // East Asia highlight
  [
    GeoPoint(35, 110), GeoPoint(35, 130), GeoPoint(20, 120), GeoPoint(20, 105),
    GeoPoint(30, 95), GeoPoint(40, 95), GeoPoint(45, 110), GeoPoint(35, 110),
  ],
  // SE Asia
  [
    GeoPoint(5, 100), GeoPoint(10, 110), GeoPoint(0, 115), GeoPoint(-8, 110),
    GeoPoint(-5, 100), GeoPoint(0, 95), GeoPoint(5, 100),
  ],
  // Middle East
  [
    GeoPoint(35, 35), GeoPoint(35, 55), GeoPoint(20, 55), GeoPoint(15, 45),
    GeoPoint(25, 35), GeoPoint(35, 35),
  ],
  // Australia
  [
    GeoPoint(-20, 115), GeoPoint(-20, 145), GeoPoint(-35, 150), GeoPoint(-38, 140),
    GeoPoint(-32, 120), GeoPoint(-25, 115), GeoPoint(-20, 115),
  ],
];

const List<_City> _majorCities = [
  // North America
  _City(40.7, -74.0, 'NEW YORK', size: 9),
  _City(34.0, -118.2, 'LOS ANGELES', size: 8),
  _City(37.7, -122.4, 'SAN FRANCISCO', size: 8),
  _City(41.8, -87.6, 'CHICAGO', size: 8),
  _City(25.7, -80.2, 'MIAMI', size: 7),
  _City(19.4, -99.1, 'MEXICO CITY', size: 8),
  _City(43.6, -79.3, 'TORONTO', size: 7),
  _City(45.5, -73.5, 'MONTREAL', size: 6),
  // South America
  _City(-23.5, -46.6, 'SÃO PAULO', size: 9),
  _City(-34.6, -58.4, 'BUENOS AIRES', size: 8),
  _City(-12.0, -77.0, 'LIMA', size: 7),
  _City(4.6, -74.0, 'BOGOTÁ', size: 7),
  _City(-33.4, -70.6, 'SANTIAGO', size: 7),
  // Europe
  _City(51.5, -0.1, 'LONDON', size: 9),
  _City(48.8, 2.3, 'PARIS', size: 9),
  _City(52.5, 13.4, 'BERLIN', size: 8),
  _City(41.9, 12.5, 'ROME', size: 8),
  _City(40.4, -3.7, 'MADRID', size: 8),
  _City(52.3, 4.9, 'AMSTERDAM', size: 7),
  _City(55.6, 13.0, 'STOCKHOLM', size: 6),
  _City(59.3, 18.0, 'OSLO', size: 6),
  _City(53.3, -6.2, 'DUBLIN', size: 6),
  _City(50.0, 8.6, 'FRANKFURT', size: 7),
  _City(47.3, 8.5, 'ZURICH', size: 6),
  // Africa
  _City(-26.2, 28.0, 'JOHANNESBURG', size: 7),
  _City(-1.3, 36.8, 'NAIROBI', size: 6),
  _City(30.0, 31.2, 'CAIRO', size: 8),
  _City(6.5, 3.3, 'LAGOS', size: 7),
  _City(-33.9, 18.4, 'CAPE TOWN', size: 7),
  // Middle East
  _City(25.2, 55.3, 'DUBAI', size: 9),
  _City(24.4, 54.4, 'ABU DHABI', size: 7),
  _City(21.5, 39.2, 'JEDDAH', size: 7),
  _City(31.9, 35.9, 'AMMAN', size: 6),
  // Asia
  _City(28.6, 77.2, 'NEW DELHI', size: 9),
  _City(19.0, 72.8, 'MUMBAI', size: 8),
  _City(12.9, 77.6, 'BANGALORE', size: 7),
  _City(22.5, 88.3, 'KOLKATA', size: 7),
  _City(13.7, 100.5, 'BANGKOK', size: 8),
  _City(14.6, 121.0, 'MANILA', size: 7),
  _City(3.1, 101.6, 'KUALA LUMPUR', size: 8),
  _City(1.3, 103.8, 'SINGAPORE', size: 9),
  _City(-6.2, 106.8, 'JAKARTA', size: 8),
  _City(10.7, 106.6, 'HO CHI MINH', size: 7),
  _City(13.7, 100.5, 'BANGKOK', size: 8),
  _City(35.6, 139.6, 'TOKYO', size: 9),
  _City(37.5, 127.0, 'SEOUL', size: 8),
  _City(39.9, 116.4, 'BEIJING', size: 9),
  _City(31.2, 121.5, 'SHANGHAI', size: 9),
  _City(22.3, 114.2, 'HONG KONG', size: 8),
  _City(25.0, 121.5, 'TAIPEI', size: 7),
  _City(1.3, 103.8, 'SINGAPORE', size: 9),
  // Australia
  _City(-33.8, 151.2, 'SYDNEY', size: 9),
  _City(-37.8, 144.9, 'MELBOURNE', size: 8),
  _City(-31.9, 115.8, 'PERTH', size: 6),
  _City(-27.4, 153.0, 'BRISBANE', size: 7),
  // NZ
  _City(-36.8, 174.7, 'AUCKLAND', size: 7),
  // S. America
  _City(-22.9, -43.1, 'RIO', size: 7),
];

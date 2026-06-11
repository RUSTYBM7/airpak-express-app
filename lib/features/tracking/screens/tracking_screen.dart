import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../../../app/design_system.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/data/repositories.dart';
import '../../../core/models/shipment.dart';
import '../../../core/services/map_config.dart';
import '../../../core/services/wallet_service.dart';
import '../../auth/providers/auth_controller.dart';

final _trackProvider = FutureProvider.family
    .autoDispose<RepoResult<TrackingLookup>, String>((ref, tracking) async {
  final repo = ref.watch(shipmentRepoProvider);
  final ship = await repo.getByTracking(tracking);
  if (ship.data == null) return RepoResult.ok(TrackingLookup.notFound());
  final events = await repo.events(ship.data!.id);
  return RepoResult.ok(TrackingLookup.found(ship.data!, events.data ?? const []));
});

class TrackingLookup {
  final Shipment? shipment;
  final List<TrackingEvent> events;
  final bool found;
  const TrackingLookup._({this.shipment, this.events = const [], required this.found});
  factory TrackingLookup.found(Shipment s, List<TrackingEvent> e) =>
      TrackingLookup._(shipment: s, events: e, found: true);
  factory TrackingLookup.notFound() => const TrackingLookup._(found: false);
}

/// Full-screen iOS-style tracking experience.
///
/// Layout (top → bottom):
///   - Full-bleed MapLibre map with route line + animated marker
///   - Status pill (top-left, glass)
///   - Tracking number / brand (top-right, glass)
///   - Floating glass status card (lower-center)
///   - Draggable bottom sheet with timeline + actions
class TrackingScreen extends ConsumerStatefulWidget {
  final String? initialTracking;
  const TrackingScreen({super.key, this.initialTracking});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  late final TextEditingController _ctrl;
  MaplibreMapController? _mapController;
  bool _sheetExpanded = false;
  int _activeEventIndex = 0;
  // ignore: unused_field
  int _sheetSize = 0;
  final _sheetController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialTracking ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _track() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    context.go('${AppRoutes.tracking}/$t');
  }

  @override
  Widget build(BuildContext context) {
    final tracking = widget.initialTracking;
    final async = tracking == null
        ? AsyncValue<RepoResult<TrackingLookup>>.data(
            RepoResult<TrackingLookup>.ok(TrackingLookup.notFound()))
        : ref.watch(_trackProvider(tracking));

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: async.when(
        loading: () => const _LoadingMap(),
        error: (e, _) => _NotFoundView(
            error: e.toString(),
            onRetry: () => ref.invalidate(_trackProvider)),
        data: (res) {
          final lookup = res.data;
          if (lookup == null || !lookup.found || lookup.shipment == null) {
            return _SearchView(
              controller: _ctrl,
              onSubmit: _track,
            );
          }
          return _TrackingMapView(
            shipment: lookup.shipment!,
            events: lookup.events,
            mapController: _mapController,
            onMapCreated: (c) => _mapController = c,
            sheetController: _sheetController,
            sheetExpanded: _sheetExpanded,
            onSheetChanged: (v) => setState(() => _sheetExpanded = v),
            onBack: () => context.go(AppRoutes.home),
            onShare: () {/* share intent */},
            onWallet: () async {
              final ok =
                  await WalletService.instance.presentForShipment(lookup.shipment!);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok
                    ? 'Added to Apple Wallet'
                    : 'Wallet not available on this device')),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────

class _LoadingMap extends StatelessWidget {
  const _LoadingMap();
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1F2937), Color(0xFF374151)],
            ),
          ),
        ),
        const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.4,
          ),
        ),
      ],
    );
  }
}

class _NotFoundView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _NotFoundView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1F2937), Color(0xFF111827)],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => context.go(AppRoutes.home),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white, size: 36),
                      const SizedBox(height: 12),
                      Text(error,
                          style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: onRetry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchView extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  const _SearchView({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Backdrop
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFFDC2626)],
              stops: [0, 0.6, 1.0],
            ),
          ),
        ),
        // Glow circles
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.white.withValues(alpha: 0.15), Colors.transparent],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    _GlassIconButton(
                      icon: Icons.arrow_back_ios_new,
                      onTap: () => context.go(AppRoutes.home),
                    ),
                    const Spacer(),
                    const Text(
                      'Track shipment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    _GlassIconButton(
                      icon: Icons.qr_code_scanner,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Camera scan mocked in this build')),
                        );
                      },
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Real-time tracking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter any AirPak Express tracking number starting with "APK".',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: controller,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'APK…',
                          hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.08),
                          prefixIcon: Icon(Icons.search,
                              color: Colors.white.withValues(alpha: 0.7)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => onSubmit(),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.brand,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Track now'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Try a sample',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in const [
                            'APK20240521001230',
                            'APK20240522001231',
                            'APK20240523001232',
                            'APK20240524001233',
                          ])
                            _GlassChip(
                              label: s,
                              onTap: () {
                                controller.text = s;
                                onSubmit();
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackingMapView extends StatefulWidget {
  final Shipment shipment;
  final List<TrackingEvent> events;
  final MaplibreMapController? mapController;
  final void Function(MaplibreMapController) onMapCreated;
  final DraggableScrollableController sheetController;
  final bool sheetExpanded;
  final ValueChanged<bool> onSheetChanged;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onWallet;

  const _TrackingMapView({
    required this.shipment,
    required this.events,
    required this.mapController,
    required this.onMapCreated,
    required this.sheetController,
    required this.sheetExpanded,
    required this.onSheetChanged,
    required this.onBack,
    required this.onShare,
    required this.onWallet,
  });

  @override
  State<_TrackingMapView> createState() => _TrackingMapViewState();
}

class _TrackingMapViewState extends State<_TrackingMapView>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _sheetAnim;
  late final Animation<double> _sheetSize;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _sheetAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: widget.sheetExpanded ? 1.0 : 0.0,
    );
    _sheetSize = CurvedAnimation(parent: _sheetAnim, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _sheetAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.shipment;
    final origin = s.origin;
    final dest = s.destination;
    final hasCoords = origin.lat != null && dest.lat != null;

    return Stack(
      children: [
        // ── Map layer ─────────────────────────────────────────────
        if (hasCoords)
          _MapView(
            origin: origin,
            dest: dest,
            mapController: widget.mapController,
            onMapCreated: widget.onMapCreated,
          )
        else
          _FallbackMapLayer(shipment: s),

        // ── Status pulse marker (overlaid) ───────────────────────
        if (hasCoords)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => _StatusPulse(
                value: _pulse.value,
                status: s.status,
              ),
            ),
          ),

        // ── Top glass bar ────────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  _GlassIconButton(icon: Icons.arrow_back_ios_new, onTap: widget.onBack),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GlassPill(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StatusDot(status: s.status),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              s.status.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _GlassIconButton(icon: Icons.ios_share, onTap: widget.onShare),
                ],
              ),
            ),
          ),
        ),

        // ── Brand mark, top right under glass bar ─────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 56,
          right: 16,
          child: _GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_shipping, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'ShipNow · ${s.trackingNumber.substring(s.trackingNumber.length - 6)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Floating status card ─────────────────────────────────
        Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16 +
              (MediaQuery.of(context).size.height * 0.10 *
                  (widget.sheetExpanded ? 0.4 : 0.0)),
          child: _StatusCard(shipment: s),
        ),

        // ── Bottom sheet ─────────────────────────────────────────
        Positioned.fill(
          child: DraggableScrollableSheet(
            controller: widget.sheetController,
            initialChildSize: 0.10,
            minChildSize: 0.10,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.10, 0.40, 0.88],
            builder: (_, scroll) {
              widget.sheetController.addListener(() {
                final expanded = widget.sheetController.size > 0.2;
                if (expanded != widget.sheetExpanded) {
                  widget.onSheetChanged(expanded);
                }
              });
              return _BottomSheet(
                scrollController: scroll,
                shipment: s,
                events: widget.events,
                onWallet: widget.onWallet,
                onSupport: () => context.push(AppRoutes.portalSupport),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MapView extends StatelessWidget {
  final Address origin;
  final Address dest;
  final MaplibreMapController? mapController;
  final void Function(MaplibreMapController) onMapCreated;
  const _MapView({
    required this.origin,
    required this.dest,
    required this.mapController,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    return MaplibreMap(
      styleString: MapConfig.styleUrl,
      initialCameraPosition: CameraPosition(
        target: LatLng(
          (origin.lat! + dest.lat!) / 2,
          (origin.lng! + dest.lng!) / 2,
        ),
        zoom: 4.2,
        tilt: 35,
        bearing: 0,
      ),
      myLocationEnabled: false,
      myLocationTrackingMode: MyLocationTrackingMode.None,
      onMapCreated: onMapCreated,
      onStyleLoadedCallback: () async {
        final c = mapController;
        if (c == null) return;
        // Draw a curved route between the two points.
        final line = <LatLng>[
          LatLng(origin.lat!, origin.lng!),
          LatLng(
            (origin.lat! + dest.lat!) / 2 + 0.6,
            (origin.lng! + dest.lng!) / 2 + 0.4,
          ),
          LatLng(dest.lat!, dest.lng!),
        ];
        await c.addLine(
          LineOptions(
            geometry: line,
            lineColor: '#DC2626',
            lineWidth: 4.0,
            lineOpacity: 0.9,
          ),
        );
        // Drop the destination marker.
        await c.addSymbol(
          SymbolOptions(
            geometry: LatLng(dest.lat!, dest.lng!),
            iconImage: 'pin',
            iconSize: 1.2,
          ),
        );
        // Fit the camera to show both points.
        final bounds = LatLngBounds(
          southwest: LatLng(
            math.min(origin.lat!, dest.lat!),
            math.min(origin.lng!, dest.lng!),
          ),
          northeast: LatLng(
            math.max(origin.lat!, dest.lat!),
            math.max(origin.lng!, dest.lng!),
          ),
        );
        await c.animateCamera(CameraUpdate.newLatLngBounds(bounds,
            left: 60, right: 60, top: 120, bottom: 320));
      },
    );
  }
}

class _FallbackMapLayer extends StatelessWidget {
  final Shipment shipment;
  const _FallbackMapLayer({required this.shipment});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF312E81), Color(0xFF831843)],
        ),
      ),
      child: CustomPaint(painter: _GridPainter()),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatusPulse extends StatelessWidget {
  final double value;
  final ShipmentStatus status;
  const _StatusPulse({required this.value, required this.status});
  @override
  Widget build(BuildContext context) {
    // Centre overlay roughly between origin and destination
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: 120 + 60 * value,
        height: 120 + 60 * value,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _statusColor(status).withValues(alpha: 1 - value),
              width: 3,
            ),
          ),
        ),
      ),
    );
  }
}

Color _statusColor(ShipmentStatus s) {
  switch (s) {
    case ShipmentStatus.delivered:
      return AppColors.success;
    case ShipmentStatus.outForDelivery:
      return AppColors.info;
    case ShipmentStatus.exception:
      return AppColors.brand;
    case ShipmentStatus.cancelled:
    case ShipmentStatus.returned:
      return AppColors.textMuted;
    default:
      return AppColors.warning;
  }
}

class _StatusDot extends StatelessWidget {
  final ShipmentStatus status;
  const _StatusDot({required this.status});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _statusColor(status),
        boxShadow: [
          BoxShadow(
            color: _statusColor(status).withValues(alpha: 0.6),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Shipment shipment;
  const _StatusCard({required this.shipment});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: QrImageView(
                      data: shipment.trackingNumber,
                      size: 38,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shipment.trackingNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.bolt,
                                color: Colors.white70, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '${shipment.service} · ETA ${shipment.etaFormatted}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(shipment.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      shipment.status.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: shipment.status.progress,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _MiniStat(
                    label: 'Origin',
                    value: shipment.origin.city,
                    icon: Icons.flag,
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward,
                      color: Colors.white60, size: 14),
                  const Spacer(),
                  _MiniStat(
                    label: 'Destination',
                    value: shipment.destination.city,
                    icon: Icons.location_on,
                  ),
                  const Spacer(),
                  _MiniStat(
                    label: 'Price',
                    value: shipment.priceFormatted,
                    icon: Icons.attach_money,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white60, size: 12),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 9)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

class _BottomSheet extends StatelessWidget {
  final ScrollController scrollController;
  final Shipment shipment;
  final List<TrackingEvent> events;
  final VoidCallback onWallet;
  final VoidCallback onSupport;
  const _BottomSheet({
    required this.scrollController,
    required this.shipment,
    required this.events,
    required this.onWallet,
    required this.onSupport,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const Text(
                'Tracking history',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Pull up for full timeline',
                style: TextStyle(color: context.textMutedColor, fontSize: 12),
              ),
              const SizedBox(height: 14),
              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: _ActionPill(
                      icon: Icons.account_balance_wallet,
                      label: 'Apple Wallet',
                      onTap: onWallet,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionPill(
                      icon: Icons.support_agent,
                      label: 'Support',
                      onTap: onSupport,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionPill(
                      icon: Icons.print,
                      label: 'Label',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Label download started')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ..._buildTimeline(context),
              const SizedBox(height: 12),
              _RouteCard(shipment: shipment),
              const SizedBox(height: 12),
              _PackageCard(shipment: shipment),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTimeline(BuildContext context) {
    if (events.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text('No tracking events yet.'),
        ),
      ];
    }
    return [
      for (var i = 0; i < events.length; i++)
        TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.2,
          isFirst: i == 0,
          isLast: i == events.length - 1,
          indicatorStyle: IndicatorStyle(
            width: 22,
            color: i == 0 ? AppColors.brand : AppColors.border,
            iconStyle: IconStyle(
              iconData: i == 0 ? Icons.radio_button_checked : Icons.check,
              color: Colors.white,
            ),
          ),
          beforeLineStyle: LineStyle(
            color: i == 0 ? AppColors.brand : AppColors.border,
            thickness: 2,
          ),
          endChild: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 0, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(events[i].status.label,
                    style:
                        const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(events[i].location,
                    style: TextStyle(
                        color: context.textMutedColor, fontSize: 12)),
                if (events[i].description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(events[i].description!,
                        style: const TextStyle(fontSize: 12)),
                  ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(events[i].occurredAt),
                  style: TextStyle(
                      color: context.textMutedColor, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
    ];
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionPill(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.brand, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final Shipment shipment;
  const _RouteCard({required this.shipment});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _addressRow(context, Icons.flag, 'From', shipment.origin),
          const Divider(height: 18),
          _addressRow(context, Icons.location_on, 'To', shipment.destination),
        ],
      ),
    );
  }

  Widget _addressRow(BuildContext context, IconData icon, String label, Address a) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.brandLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.brand, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$label · ${a.name}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(a.oneLine,
                  style: TextStyle(
                      color: context.textMutedColor, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PackageCard extends StatelessWidget {
  final Shipment shipment;
  const _PackageCard({required this.shipment});
  @override
  Widget build(BuildContext context) {
    final p = shipment.package;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
              child: _infoTile(context, 'Weight',
                  '${p.weightKg.toStringAsFixed(1)} kg')),
          Expanded(
              child: _infoTile(context, 'Dimensions',
                  '${p.lengthCm.toInt()}×${p.widthCm.toInt()}×${p.heightCm.toInt()} cm')),
          Expanded(child: _infoTile(context, 'Pieces', '${p.pieces}')),
        ],
      ),
    );
  }

  Widget _infoTile(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: context.textMutedColor,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── Glass primitives ──────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _GlassCard({required this.child, this.padding = const EdgeInsets.all(12)});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final Widget child;
  const _GlassPill({required this.child});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            borderRadius: BorderRadius.circular(99),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GlassChip({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

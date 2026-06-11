import 'package:maplibre_gl/maplibre_gl.dart';

import '../config/env.dart';

/// Resolves the active map provider into a MapLibre style URL + camera
/// options the screens can consume directly.
///
/// Tile providers are configured via --dart-define:
///
///   MAP_PROVIDER=maptiler  --dart-define=MAPTILER_KEY=pk.xxx
///   MAP_PROVIDER=mapbox     --dart-define=MAPBOX_TOKEN=pk.xxx
///   MAP_PROVIDER=stadia     --dart-define=STADIA_KEY=xxx
///   MAP_PROVIDER=custom     --dart-define=MAPLIBRE_STYLE_URL=https://...
///   MAP_PROVIDER=demotiles  (default — free MapLibre demo)
class MapConfig {
  const MapConfig._();

  static const _maptilerStreets =
      'https://api.maptiler.com/maps/streets/style.json';
  static const _maptilerStreetsDark =
      'https://api.maptiler.com/maps/streets-dark/style.json';
  static const _mapboxStreets =
      'mapbox://styles/mapbox/streets-v12';
  static const _stadiaAlidadeSmooth =
      'https://tiles.stadiamaps.com/styles/alidade_smooth.json';
  // ignore: unused_field
  static const _stadiaAlidadeSmoothDark =
      'https://tiles.stadiamaps.com/styles/alidade_smooth_dark.json';

  /// The style URL the MapLibre widget should load.
  static String get styleUrl {
    switch (AppEnv.mapProvider) {
      case 'maptiler':
        if (AppEnv.maptilerKey.isEmpty) {
          return _maptilerStreetsDark;
        }
        return '$_maptilerStreets?key=${AppEnv.maptilerKey}';
      case 'mapbox':
        if (AppEnv.mapboxToken.isEmpty) return _maptilerStreetsDark;
        return '$_mapboxStreets?access_token=${AppEnv.mapboxToken}';
      case 'stadia':
        if (AppEnv.stadiaKey.isEmpty) return _stadiaAlidadeSmooth;
        return '$_stadiaAlidadeSmooth?api_key=${AppEnv.stadiaKey}';
      case 'custom':
        return AppEnv.maplibreStyleUrl;
      case 'demotiles':
      default:
        return AppEnv.maplibreStyleUrl;
    }
  }

  /// Dark-themed style URL — falls back to a free dark Carto style that
  /// works without any API key. Used by the iOS-Maps-style full-screen
  /// tracking page.
  static String get darkStyle {
    // Carto's "Dark Matter" GL style is free, includes roads/labels
    // for the whole planet, and is exactly the "Apple Maps dark" look.
    const _cartoDarkMatter = 'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json';
    switch (AppEnv.mapProvider) {
      case 'maptiler':
        if (AppEnv.maptilerKey.isEmpty) {
          return _cartoDarkMatter;
        }
        return '$_maptilerStreetsDark?key=${AppEnv.maptilerKey}';
      case 'mapbox':
        return AppEnv.mapboxToken.isEmpty
            ? _cartoDarkMatter
            : 'mapbox://styles/mapbox/dark-v11?access_token=${AppEnv.mapboxToken}';
      case 'stadia':
        return AppEnv.stadiaKey.isEmpty
            ? 'https://tiles.stadiamaps.com/styles/alidade_smooth_dark.json'
            : 'https://tiles.stadiamaps.com/styles/alidade_smooth_dark.json?api_key=${AppEnv.stadiaKey}';
      case 'custom':
        return AppEnv.maplibreStyleUrl;
      case 'demotiles':
      default:
        return _cartoDarkMatter;
    }
  }

  /// Initial camera position — centred on Malaysia, zoomed to a level
  /// that shows the whole region.
  static CameraPosition get defaultCamera => const CameraPosition(
        bearing: 0,
        target: LatLng(3.139, 101.6869),
        tilt: 0,
        zoom: 3.6,
      );

  /// Tile provider name for display in the UI.
  static String get providerName {
    switch (AppEnv.mapProvider) {
      case 'maptiler':
        return 'MapTiler';
      case 'mapbox':
        return 'Mapbox';
      case 'stadia':
        return 'Stadia Maps';
      case 'custom':
        return 'Custom style';
      case 'demotiles':
      default:
        return 'MapLibre demo';
    }
  }
}

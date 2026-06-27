import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

/// Smartsupp controller — mounts the Smartsupp widget only on public
/// marketing routes. Strips it out the moment the user enters an
/// authenticated app route.
const _publicRoutes = <String>{
  '/',
  '/welcome',
  '/onboarding',
  '/terms',
  '/privacy',
};

class SmartsuppController {
  SmartsuppController();

  bool _currentState = false;

  /// Sync the Smartsupp widget with the active route.
  void syncWithRoute(String location) {
    final shouldEnable = _publicRoutes.contains(location);
    if (shouldEnable == _currentState) return;
    _currentState = shouldEnable;
    if (kIsWeb) {
      _dispatch(shouldEnable);
    }
  }

  /// Dispatches a DOM CustomEvent the smartsupp_bridge.js listens for.
  void _dispatch(bool enable) {
    try {
      final jsCode =
          'window.dispatchEvent(new CustomEvent("airpak-smartsupp",'
          '{detail:{enable:$enable}}))';
      // Use a script tag trick to run the dispatch synchronously.
      final script = web.document.createElement('script') as web.HTMLScriptElement;
      script.text = jsCode;
      web.document.head?.appendChild(script);
      web.document.head?.removeChild(script);
    } catch (_) {}
  }
}

final smartsuppControllerProvider = Provider<SmartsuppController>((ref) {
  return SmartsuppController();
});
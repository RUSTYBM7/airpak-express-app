// Smartsupp loader — only mounts when window.AIRPAK_PUBLIC === true.
// The Flutter app sets this flag based on the active route.
// Inside the app, the flag is cleared so Smartsupp is hidden.
(function () {
  var SMARTSUPP_KEY = '27aadb72e99dda406a9724bb9421ba336f62b73f';
  var mounted = false;
  var scriptEl = null;
  var lastState = null;

  function mountSmartsupp() {
    if (mounted) return;
    mounted = true;
    lastState = true;
    window._smartsupp = window._smartsupp || function () {
      (window._smartsupp.a = window._smartsupp.a || []).push(arguments);
    };
    window._smartsupp.key = SMARTSUPP_KEY;
    scriptEl = document.createElement('script');
    scriptEl.type = 'text/javascript';
    scriptEl.async = true;
    scriptEl.src = 'https://www.smartsuppchat.com/loader.js?';
    document.head.appendChild(scriptEl);
    console.info('[smartsupp] mounted');
  }

  function unmountSmartsupp() {
    if (!mounted) return;
    mounted = false;
    lastState = false;
    if (scriptEl && scriptEl.parentNode) {
      scriptEl.parentNode.removeChild(scriptEl);
      scriptEl = null;
    }
    // Drop the chat widget if rendered.
    var widget = document.getElementById('smartsupp-widget-container')
      || document.querySelector('[id^="smartsupp"]');
    if (widget) widget.remove();
    try { delete window._smartsupp; } catch (_) { window._smartsupp = undefined; }
    console.info('[smartsupp] unmounted');
  }

  // Initial state from the Flutter side via window.AIRPAK_PUBLIC.
  function sync() {
    var enabled = window.AIRPAK_PUBLIC === true;
    if (enabled === lastState) return;
    if (enabled) mountSmartsupp();
    else unmountSmartsupp();
  }

  // Listen for explicit dispatch (preferred path).
  window.addEventListener('airpak-smartsupp', function (ev) {
    if (ev.detail && ev.detail.enable) mountSmartsupp();
    else unmountSmartsupp();
  });

  // Poll window.AIRPAK_PUBLIC every animation frame.
  function tick() {
    sync();
    requestAnimationFrame(tick);
  }
  requestAnimationFrame(tick);

  window.AIRPAK_SMARTSUPP_API = {
    enable: mountSmartsupp,
    disable: unmountSmartsupp,
    isMounted: function () { return mounted; },
  };
})();
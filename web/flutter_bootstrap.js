{{flutter_js}}
{{flutter_build_config}}

// Flutter 3.47's generated flutter_service_worker.js only unregisters legacy
// workers. Register this app's own worker so the shell is cached for offline use.
if ('serviceWorker' in navigator) {
  const workerUrl = new URL('sw.js', window.location.href);
  navigator.serviceWorker.register(workerUrl);
}

_flutter.loader.load();

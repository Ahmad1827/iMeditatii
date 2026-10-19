{{flutter_js}}
{{flutter_build_config}}

// No serviceWorkerSettings: Flutter's own worker only unregisters itself now,
// and it would take the place of web/sw.js (registered in index.html).
_flutter.loader.load();

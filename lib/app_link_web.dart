import 'dart:js_interop';
import 'dart:js_interop_unsafe';

bool _armed = false;
bool _listening = false;

/// The browser's own menu stays closed for this one right click, the one the
/// app answers itself. Everywhere else right click still gives the browser's.
void keepBrowserMenuAway() {
  _armed = true;
  if (_listening) return;
  _listening = true;
  globalContext.callMethod(
    'addEventListener'.toJS,
    'contextmenu'.toJS,
    ((JSObject e) {
      if (!_armed) return;
      _armed = false;
      e.callMethod('preventDefault'.toJS);
    }).toJS,
    true.toJS,
  );
}

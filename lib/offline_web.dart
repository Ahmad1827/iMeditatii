import 'dart:js_interop';
import 'dart:js_interop_unsafe';

bool online() => (globalContext.getProperty<JSObject>('navigator'.toJS).getProperty<JSBoolean?>('onLine'.toJS))?.toDart ?? true;

void listen(void Function(bool online) onChange) {
  globalContext.callMethod('addEventListener'.toJS, 'online'.toJS, ((JSAny? _) => onChange(true)).toJS);
  globalContext.callMethod('addEventListener'.toJS, 'offline'.toJS, ((JSAny? _) => onChange(false)).toJS);
}

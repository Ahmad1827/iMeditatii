import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'brand_mark.dart' show BrandLogo, BrandMark;
import 'code_workbench.dart';
import 'theme_manager.dart';
import 'ui_components.dart' show Pb, PbButton, PbVariant, PbSize, showPbModal;

// =============================================================================
// IDE — the editor alone, on the whole screen, at /ide. A link can carry a
// program (/ide?limbaj=cpp&cod=…&in=…): "Distribuie" copies one with the code
// as it is, so a teacher sends a program and the student opens it ready to run.
// Without a link, the last program written here comes back.
// =============================================================================
class IdeScreen extends StatefulWidget {
  final String? code; // from the link, base64url
  final String? lang;
  final String? input; // base64url

  const IdeScreen({super.key, this.code, this.lang, this.input});

  /// The link that opens [code] here.
  static String linkFor(String code, String lang, String input) {
    final q = {'limbaj': lang, 'cod': _enc(code), if (input.trim().isNotEmpty) 'in': _enc(input)};
    return '${Uri.base.origin}${Uri(path: '/ide', queryParameters: q)}';
  }

  static String _enc(String s) => base64Url.encode(utf8.encode(s)).replaceAll('=', '');

  static String? _dec(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return utf8.decode(base64Url.decode(base64Url.normalize(s)), allowMalformed: true);
    } catch (_) {
      return null;
    }
  }

  @override
  State<IdeScreen> createState() => _IdeScreenState();
}

class _IdeScreenState extends State<IdeScreen> {
  static const _kCode = 'ide_code';
  static const _kLang = 'ide_lang';
  static const _kInput = 'ide_input';

  static const Map<String, String> _starters = {
    'cpp': '#include <iostream>\nusing namespace std;\n\nint main() {\n    int n;\n    cin >> n;\n    cout << n * 2 << "\\n";\n    return 0;\n}\n',
    'python': 'n = int(input())\nprint(n * 2)\n',
  };

  String? _code;
  String _lang = 'cpp';
  String _input = '5';
  bool _fromLink = false;
  int _gen = 0; // a new workbench (a new program) when it changes

  @override
  void initState() {
    super.initState();
    // the theme deck and the homework dock stay away from a full-screen editor
    Future.microtask(() => ThemeManager.focusNotifier.value = true);
    _load();
  }

  @override
  void dispose() {
    Future.microtask(() => ThemeManager.focusNotifier.value = false);
    super.dispose();
  }

  Future<void> _load() async {
    final linked = IdeScreen._dec(widget.code);
    final lang = widget.lang == 'python' ? 'python' : 'cpp';
    if (linked != null) {
      setState(() {
        _fromLink = true;
        _lang = widget.lang == null ? 'cpp' : lang;
        _code = linked;
        _input = IdeScreen._dec(widget.input) ?? '';
      });
      return;
    }
    String? code;
    String savedLang = 'cpp';
    String? input;
    try {
      final p = await SharedPreferences.getInstance();
      savedLang = p.getString(_kLang) == 'python' ? 'python' : 'cpp';
      code = p.getString(_kCode);
      input = p.getString(_kInput);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _lang = savedLang;
      _code = code ?? _starters[savedLang]!;
      _input = input ?? '5';
    });
  }

  void _save(String key, String value) {
    SharedPreferences.getInstance().then((p) => p.setString(key, value)).catchError((_) => false);
  }

  void _onCode(String c) {
    _code = c;
    _save(_kCode, c);
  }

  void _onLang(String l) {
    final untouched = (_code ?? '').trim().isEmpty || _code!.trim() == _starters[_lang]!.trim();
    _lang = l;
    _save(_kLang, l);
    // the example program of the other language, while nothing is written yet
    if (untouched) {
      setState(() {
        _code = _starters[l]!;
        _gen++;
      });
      _save(_kCode, _code!);
    }
  }

  void _onInput(String s) {
    _input = s;
    _save(_kInput, s);
  }

  void _toast(String msg) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 3), behavior: SnackBarBehavior.floating));
  }

  void _share() {
    final link = IdeScreen.linkFor(_code ?? '', _lang, _input);
    Clipboard.setData(ClipboardData(text: link));
    _toast(link.length > 6000
        ? 'Linkul a fost copiat (e lung, pentru că are tot programul în el).'
        : 'Linkul a fost copiat: cine îl deschide vede programul acesta, gata de rulat.');
  }

  Future<void> _newProgram() async {
    final lang = await showPbModal<String>(
      context,
      title: 'Program nou',
      body: Text('Programul de acum se înlocuiește. Dacă vrei să-l păstrezi, copiază-l sau ia-i linkul întâi.',
          style: TextStyle(fontSize: 14, color: Pb.muted, height: 1.4)),
      actions: (ctx) => [
        PbButton(text: 'Renunță', variant: PbVariant.outlineSecondary, size: PbSize.sm, onPressed: () => Navigator.of(ctx).pop()),
        PbButton(text: 'Python 3', variant: PbVariant.outlineSecondary, size: PbSize.sm, onPressed: () => Navigator.of(ctx).pop('python')),
        PbButton(text: 'C++', size: PbSize.sm, onPressed: () => Navigator.of(ctx).pop('cpp')),
      ],
    );
    if (lang == null || !mounted) return;
    setState(() {
      _lang = lang;
      _code = _starters[lang]!;
      _input = '5';
      _fromLink = false;
      _gen++;
    });
    _save(_kLang, lang);
    _save(_kCode, _code!);
    _save(_kInput, _input);
    if (GoRouterState.of(context).uri.queryParameters.isNotEmpty) context.go('/ide');
  }

  void _keys() {
    const rows = [
      ('Ctrl+Enter', 'rulează programul'),
      ('Shift+Alt+F', 'aliniază tot codul'),
      ('Ctrl+/', 'comentează liniile'),
      ('Tab / Shift+Tab', 'indentează / scoate indentarea'),
      ('Alt+↑ / Alt+↓', 'mută linia'),
      ('Shift+Alt+↑ / ↓', 'copiază linia'),
      ('Ctrl+Shift+K', 'șterge linia'),
      ('Ctrl+Z / Ctrl+Y', 'anulează / refă'),
    ];
    showPbModal<void>(
      context,
      title: 'Scurtături',
      actions: (ctx) => [PbButton(text: 'Am înțeles', size: PbSize.sm, onPressed: () => Navigator.of(ctx).pop())],
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(r.$1, style: Pb.mono(13, color: Pb.text)),
                  ),
                  Expanded(child: Text(r.$2, style: TextStyle(fontSize: 14, color: Pb.muted))),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text('Parantezele și ghilimelele se închid singure. Tab-ul Stil arată, pe cod, ce e de aranjat.',
              style: TextStyle(fontSize: 13.5, color: Pb.muted, height: 1.4)),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData i, String tip, VoidCallback f) => IconButton(
        icon: Icon(i, size: 19),
        color: Pb.muted,
        tooltip: tip,
        splashRadius: 18,
        visualDensity: VisualDensity.compact,
        onPressed: f,
      );

  Widget _bar(bool narrow) {
    return Container(
      height: 52,
      padding: EdgeInsets.symmetric(horizontal: narrow ? 8 : 16),
      decoration: BoxDecoration(color: Pb.surface, border: Border(bottom: BorderSide(color: Pb.border))),
      child: Row(
        children: [
          Tooltip(
            message: 'Pagina principală',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.go('/'),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: narrow ? const BrandMark(size: 26) : BrandLogo(color: Pb.text, accent: Pb.link, markSize: 26, fontSize: 16),
              ),
            ),
          ),
          if (!narrow) ...[
            const SizedBox(width: 12),
            Container(width: 1, height: 22, color: Pb.border),
            const SizedBox(width: 12),
          ],
          Icon(Icons.terminal, size: 18, color: Pb.primary),
          const SizedBox(width: 6),
          Text('IDE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Pb.text)),
          if (_fromLink && !narrow) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Pb.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
              child: Text('deschis dintr-un link', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Pb.primary)),
            ),
          ],
          const Spacer(),
          _iconBtn(Icons.note_add_outlined, 'Program nou', _newProgram),
          _iconBtn(Icons.keyboard_outlined, 'Scurtături', _keys),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeManager.themeNotifier,
            builder: (_, m, __) => _iconBtn(
              m == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              m == ThemeMode.dark ? 'Temă luminoasă' : 'Temă întunecată',
              ThemeManager.toggleTheme,
            ),
          ),
          const SizedBox(width: 6),
          narrow
              ? _iconBtn(Icons.link, 'Distribuie (copiază linkul)', _share)
              : PbButton(text: 'Distribuie', icon: Icons.link, variant: PbVariant.outlineSecondary, size: PbSize.sm, onPressed: _share),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: Pb.editorBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _bar(narrow),
            Expanded(
              child: _code == null
                  ? const Center(child: CircularProgressIndicator(color: Pb.primary))
                  : CodeWorkbench(
                      key: ValueKey(_gen),
                      initialCode: _code!,
                      initialLang: _lang,
                      initialStdin: _input,
                      compact: narrow,
                      styleCheck: true,
                      sideConsole: true,
                      onCodeChanged: _onCode,
                      onLangChanged: _onLang,
                      onStdinChanged: _onInput,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

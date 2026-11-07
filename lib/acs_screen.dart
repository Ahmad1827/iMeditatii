// =============================================================================
// ACS: problems for the Faculty of Automatic Control and Computers (UPB)
//   A section of its own, with its own look: a terminal, or a notebook page,
//   each in light and dark, all set in Iosevka. The switches sit top right;
//   light / dark is the app's own theme, Terminal / Notebook is remembered apart.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_link.dart';
import 'theme_manager.dart';

/// A subject of the section. The problems come later; until then a subject
/// shows as coming soon.
class AcsSubject {
  final String code; // the folder name in the terminal: "pc"
  final String name;
  final String about;
  final int problems;
  final int solved;
  const AcsSubject(this.code, this.name, this.about, {this.problems = 0, this.solved = 0});
}

const List<AcsSubject> acsSubjects = [
  AcsSubject('admitere', 'Admitere ACS', 'Subiectele de matematică și informatică de la admitere'),
  AcsSubject('pc', 'Programarea Calculatoarelor', 'C: pointeri, alocare dinamică, fișiere, structuri'),
  AcsSubject('uso', 'Utilizarea Sistemelor de Operare', 'Shell, permisiuni, procese, scripturi'),
  AcsSubject('sda', 'Structuri de Date și Algoritmi', 'Liste, stive, cozi, arbori, tabele de dispersie'),
  AcsSubject('poo', 'Programare Orientată pe Obiecte', 'Clase, moștenire, polimorfism'),
  AcsSubject('pa', 'Proiectarea Algoritmilor', 'Divide et impera, programare dinamică, greedy, grafuri'),
];

const String _font = 'Iosevka';
const List<String> _fallback = ['monospace'];

/// The colours of one look in one theme.
class _Ink {
  final Color bg, fg, strong, accent, muted, dim, line, hover;
  const _Ink({
    required this.bg,
    required this.fg,
    required this.strong,
    required this.accent,
    required this.muted,
    required this.dim,
    required this.line,
    required this.hover,
  });

  static _Ink of(AcsStyle style, bool dark) {
    if (style == AcsStyle.terminal) {
      return dark
          ? const _Ink(
              bg: Color(0xFF121513), fg: Color(0xFFCFD6C9), strong: Color(0xFFE9EFE2), accent: Color(0xFF9FCF8F),
              muted: Color(0xFF7D887A), dim: Color(0xFF4B544A), line: Color(0xFF2A302A), hover: Color(0xFF1A1F1B))
          : const _Ink(
              bg: Color(0xFFF2F4EF), fg: Color(0xFF243025), strong: Color(0xFF111A12), accent: Color(0xFF2F7A3A),
              muted: Color(0xFF5D6B5C), dim: Color(0xFFA3AD9F), line: Color(0xFFD3D9CF), hover: Color(0xFFE6EAE2));
    }
    return dark
        ? const _Ink(
            bg: Color(0xFF1B1C1E), fg: Color(0xFFDADAD6), strong: Color(0xFFF0F0EC), accent: Color(0xFF8AB4F0),
            muted: Color(0xFF9A9A96), dim: Color(0xFF6A6B6E), line: Color(0xFF4A4B4E), hover: Color(0xFF252629))
        : const _Ink(
            bg: Color(0xFFFBFBF9), fg: Color(0xFF2B2B2B), strong: Color(0xFF222222), accent: Color(0xFF1F5FA8),
            muted: Color(0xFF666666), dim: Color(0xFF8A8A8A), line: Color(0xFFB9B9B9), hover: Color(0xFFF0F0EC));
  }
}

class AcsScreen extends StatelessWidget {
  const AcsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ThemeManager.themeNotifier, ThemeManager.acsStyleNotifier]),
      builder: (context, _) {
        final style = ThemeManager.acsStyleNotifier.value;
        final dark = ThemeManager.isDark;
        final ink = _Ink.of(style, dark);
        final width = MediaQuery.of(context).size.width;
        final narrow = width < 600;

        final base = TextStyle(fontFamily: _font, fontFamilyFallback: _fallback, color: ink.fg, fontSize: 15, height: 1.45);

        return Scaffold(
          backgroundColor: ink.bg,
          body: DefaultTextStyle(
            style: base,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(narrow ? 16 : 32, 18, narrow ? 16 : 32, 64),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(alignment: Alignment.centerRight, child: _Switches(ink: ink, style: style, dark: dark)),
                          const SizedBox(height: 14),
                          style == AcsStyle.terminal
                              ? _Terminal(ink: ink, narrow: narrow)
                              : _Notebook(ink: ink, narrow: narrow),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- switches
class _Switches extends StatelessWidget {
  final _Ink ink;
  final AcsStyle style;
  final bool dark;
  const _Switches({required this.ink, required this.style, required this.dark});

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, AcsStyle s) {
      final on = style == s;
      return _Tap(
        label: 'Aspect $label',
        onTap: () => ThemeManager.setAcsStyle(s),
        builder: (h) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: on ? ink.accent : (h ? ink.hover : Colors.transparent),
          child: Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: on ? ink.bg : ink.muted)),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(border: Border.all(color: ink.line)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [seg('terminal', AcsStyle.terminal), seg('notebook', AcsStyle.notebook)]),
        ),
        const SizedBox(width: 8),
        _Tap(
          label: dark ? 'Temă luminoasă' : 'Temă întunecată',
          onTap: ThemeManager.toggleTheme,
          builder: (h) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(border: Border.all(color: ink.line), color: h ? ink.hover : Colors.transparent),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 15, color: ink.fg),
                const SizedBox(width: 6),
                Text(dark ? 'light' : 'dark', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink.fg)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A clickable bit of text: hand cursor, hover state, read out as a button.
class _Tap extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Widget Function(bool hover) builder;
  const _Tap({required this.label, required this.onTap, required this.builder});

  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _h = true),
        onExit: (_) => setState(() => _h = false),
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTap, child: widget.builder(_h)),
      ),
    );
  }
}

/// "materii | ← iMeditatii": the section's links, split by pipes.
class _Nav extends StatelessWidget {
  final _Ink ink;
  final double size;
  const _Nav({required this.ink, this.size = 15});

  @override
  Widget build(BuildContext context) {
    Widget link(String t, String to, {bool on = false}) => AppLink(
          to: to,
          child: _Tap(
            label: t,
            onTap: () => context.go(to),
            builder: (h) => Text(t,
                style: TextStyle(
                    fontSize: size,
                    fontWeight: FontWeight.w700,
                    color: on ? ink.accent : ink.strong,
                    decoration: h ? TextDecoration.underline : null,
                    decorationColor: on ? ink.accent : ink.strong)),
          ),
        );
    Widget pipe() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('|', style: TextStyle(fontSize: size, color: ink.dim)),
        );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: [link('materii', '/acs', on: true), pipe(), link('← iMeditatii', '/exercitii')],
    );
  }
}

/// "██████░░░░ 61%", or "în curând" while a subject has no problems.
String _bar(AcsSubject s) {
  if (s.problems == 0) return '';
  final filled = (s.solved * 10 / s.problems).round().clamp(0, 10);
  return '█' * filled;
}

String _barRest(AcsSubject s) => s.problems == 0 ? '' : '█' * (10 - (s.solved * 10 / s.problems).round().clamp(0, 10));

String _pct(AcsSubject s) => s.problems == 0 ? 'în curând' : '${(s.solved * 100 / s.problems).round()}%'.padLeft(4);

// ---------------------------------------------------------------- terminal
class _Terminal extends StatelessWidget {
  final _Ink ink;
  final bool narrow;
  const _Terminal({required this.ink, required this.narrow});

  @override
  Widget build(BuildContext context) {
    Widget prompt(String cmd) => Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 6),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: 'student@acs', style: TextStyle(color: ink.accent)),
            TextSpan(text: ':', style: TextStyle(color: ink.muted)),
            TextSpan(text: '~', style: TextStyle(color: ink.muted)),
            TextSpan(text: '\$ ', style: TextStyle(color: ink.accent)),
            TextSpan(text: cmd, style: TextStyle(color: ink.fg)),
          ])),
        );

    final cells = TextStyle(fontSize: narrow ? 13 : 14, color: ink.fg);
    final table = Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        for (final s in acsSubjects)
          TableRow(children: [
            if (!narrow) _cell(Text('drwxr-xr-x', style: cells.copyWith(color: ink.dim))),
            _cell(Text('${s.code}/', style: cells.copyWith(color: ink.accent, fontWeight: FontWeight.w700))),
            _cell(Text(s.name, style: cells)),
            if (!narrow) _cell(Text('${s.problems}', textAlign: TextAlign.right, style: cells.copyWith(color: ink.muted, fontFeatures: const [FontFeature.tabularFigures()]))),
            _cell(Text.rich(TextSpan(children: [
              TextSpan(text: _bar(s), style: TextStyle(color: ink.accent)),
              TextSpan(text: _barRest(s), style: TextStyle(color: ink.line)),
              TextSpan(text: s.problems == 0 ? _pct(s) : ' ${_pct(s)}', style: TextStyle(color: ink.muted)),
            ]), style: cells), last: true),
          ]),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ink.line))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: '~/', style: TextStyle(color: ink.accent)),
                TextSpan(text: 'acs', style: TextStyle(color: ink.strong)),
              ]), style: TextStyle(fontSize: narrow ? 28 : 34, fontWeight: FontWeight.w700, height: 1.1)),
              const SizedBox(height: 4),
              Text('probleme pentru Automatică și Calculatoare · UPB', style: TextStyle(color: ink.muted, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _Nav(ink: ink),
        prompt('ls -l materii/'),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: table),
        prompt('cat README'),
        Text('Problemele de la fiecare materie se adaugă pe rând.\nPână atunci, exersează la iMeditatii → Probleme.',
            style: TextStyle(color: ink.muted, fontSize: 14)),
        const SizedBox(height: 18),
        Row(children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: 'student@acs', style: TextStyle(color: ink.accent)),
            TextSpan(text: ':~', style: TextStyle(color: ink.muted)),
            TextSpan(text: '\$ ', style: TextStyle(color: ink.accent)),
          ])),
          _Cursor(color: ink.accent),
        ]),
      ],
    );
  }

  Widget _cell(Widget child, {bool last = false}) =>
      Padding(padding: EdgeInsets.only(right: last ? 0 : 18, top: 3, bottom: 3), child: child);
}

/// The blinking block at the prompt; still when the system asks for less motion.
class _Cursor extends StatefulWidget {
  final Color color;
  const _Cursor({required this.color});

  @override
  State<_Cursor> createState() => _CursorState();
}

class _CursorState extends State<_Cursor> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        opacity: _c.value < 0.5 ? 1 : 0,
        child: Container(width: 9, height: 18, color: widget.color),
      ),
    );
  }
}

// ---------------------------------------------------------------- notebook
class _Notebook extends StatelessWidget {
  final _Ink ink;
  final bool narrow;
  const _Notebook({required this.ink, required this.narrow});

  @override
  Widget build(BuildContext context) {
    final total = acsSubjects.fold<int>(0, (n, s) => n + s.problems);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.memory, size: 58, color: ink.strong),
        const SizedBox(height: 4),
        Text('ACS', textAlign: TextAlign.center,
            style: TextStyle(fontSize: narrow ? 34 : 42, fontWeight: FontWeight.w700, color: ink.strong, height: 1.05)),
        const SizedBox(height: 4),
        Text('Probleme pentru Automatică și Calculatoare...', textAlign: TextAlign.center,
            style: TextStyle(fontSize: narrow ? 16 : 19, color: ink.muted)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ink.line, width: 2))),
          child: _Nav(ink: ink, size: narrow ? 15 : 17),
        ),
        const SizedBox(height: 26),
        Text('Materii, anul I și II',
            style: TextStyle(fontSize: narrow ? 24 : 32, fontWeight: FontWeight.w700, color: ink.strong, height: 1.15)),
        const SizedBox(height: 4),
        Text.rich(TextSpan(children: [
          TextSpan(text: '${acsSubjects.length} materii', style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(
              text: total == 0 ? ' • problemele vin în curând' : ' • $total probleme',
              style: TextStyle(color: ink.muted)),
        ]), style: TextStyle(fontSize: 14, color: ink.fg)),
        const SizedBox(height: 22),
        for (final s in acsSubjects) ...[
          _NotebookRow(ink: ink, s: s, narrow: narrow),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _NotebookRow extends StatelessWidget {
  final _Ink ink;
  final AcsSubject s;
  final bool narrow;
  const _NotebookRow({required this.ink, required this.s, required this.narrow});

  @override
  Widget build(BuildContext context) {
    final code = Text('[${s.code.toUpperCase()}]',
        style: TextStyle(fontWeight: FontWeight.w700, color: ink.accent, fontSize: 15));
    final pct = Text(s.problems == 0 ? 'în curând' : _pct(s).trim(),
        style: TextStyle(color: ink.muted, fontSize: 14, fontFeatures: const [FontFeature.tabularFigures()]));
    final title = Text(s.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: ink.strong));
    final about = Text(
        s.problems == 0 ? s.about : '${s.about} · ${s.problems} probleme',
        style: TextStyle(color: ink.muted, fontSize: 14));

    if (narrow) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [code, const Spacer(), pct]),
        title,
        about,
      ]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Padding(padding: const EdgeInsets.only(top: 2), child: code)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, about])),
        const SizedBox(width: 16),
        Padding(padding: const EdgeInsets.only(top: 2), child: pct),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import 'clean_kit.dart';
import 'custom_navbar.dart';
import 'home_ambient.dart' show HomeSky;
import 'ui_components.dart' show StyleBuilder, AppStyle, Pb, PbButton, PbVariant, PbSize, PbAlert, PbAlertType;

class AddArticleScreen extends StatefulWidget {
  const AddArticleScreen({super.key});

  @override
  State<AddArticleScreen> createState() => _AddArticleScreenState();
}

class _AddArticleScreenState extends State<AddArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _moduleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedSubject = "PYTHON";
  String _selectedGrade = "9";
  bool _isSaving = false;

  final List<Map<String, TextEditingController>> _sections = [];

  // ---- clean state
  String? _error;
  bool _previewOnMobile = false;
  final GlobalKey _mainKey = GlobalKey();

  bool get _isAdmin => FirebaseAuth.instance.currentUser?.email == 'ahmadarnaoute1896@gmail.com';

  @override
  void initState() {
    super.initState();
    for (final c in [_titleCtrl, _moduleCtrl, _descCtrl]) {
      c.addListener(_refresh);
    }
    _sections.add(_newSection("1. Introducere"));
  }

  void _refresh() {
    if (mounted && AppStyle.current.isClean) setState(() {});
  }

  Map<String, TextEditingController> _newSection(String heading) {
    final s = {
      "heading": TextEditingController(text: heading),
      "text": TextEditingController(),
      "code": TextEditingController(),
      "callout": TextEditingController(),
    };
    for (final c in s.values) {
      c.addListener(_refresh);
    }
    return s;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _moduleCtrl.dispose();
    _descCtrl.dispose();
    for (var s in _sections) {
      for (final c in s.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _addSection() {
    setState(() => _sections.add(_newSection("${_sections.length + 1}. Secțiune nouă")));
  }

  void _removeSection(int index) {
    if (_sections.length <= 1) return;
    final s = _sections[index];
    setState(() => _sections.removeAt(index));
    for (final c in s.values) {
      c.dispose();
    }
  }

  void _moveSection(int index, int delta) {
    final j = index + delta;
    if (j < 0 || j >= _sections.length) return;
    setState(() {
      final s = _sections.removeAt(index);
      _sections.insert(j, s);
    });
  }

  int get _words {
    final all = [_descCtrl.text, for (final s in _sections) '${s["text"]!.text} ${s["callout"]!.text}'].join(' ').trim();
    return all.isEmpty ? 0 : all.split(RegExp(r'\s+')).length;
  }

  int get _codeLines => _sections.fold(0, (a, s) => a + (s["code"]!.text.trim().isEmpty ? 0 : s["code"]!.text.trim().split('\n').length));

  /// ~200 words/min for text + ~10 lines/min for code, at least 1 minute.
  int get _readMinutes => ((_words / 200) + (_codeLines / 10)).ceil().clamp(1, 120).toInt();

  Future<void> _submitArticle() async {
    final clean = AppStyle.current.isClean;
    if (!_formKey.currentState!.validate()) {
      if (clean) setState(() => _error = 'Completează câmpurile marcate cu roșu.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final authorName = userDoc.data()?['name'] ?? 'Guild Master';

      final builtSections = _sections.map((s) {
        return {
          "heading": s["heading"]!.text.trim(),
          "text": s["text"]!.text.trim(),
          "code": s["code"]!.text.trim().isEmpty ? null : s["code"]!.text.trim(),
          "callout": s["callout"]!.text.trim().isEmpty ? null : s["callout"]!.text.trim(),
          "lang": _selectedSubject == "PYTHON" ? "python" : "cpp",
        };
      }).toList();

      final now = DateTime.now();
      final articleData = {
        "title": _titleCtrl.text.trim(),
        "subject": _selectedSubject,
        "grade": _selectedGrade,
        "module": _moduleCtrl.text.trim().toUpperCase(),
        "desc": _descCtrl.text.trim(),
        "author": authorName,
        "authorUid": user.uid,
        "date": "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}",
        // estimated from the whole article now, not just the summary
        "readTime": "$_readMinutes MIN",
        "sections": builtSections,
        "approved": _isAdmin,
        "createdAt": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('resources').add(articleData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            clean
                ? (_isAdmin ? 'Lecția a fost publicată.' : 'Lecția a fost trimisă. Apare după aprobare.')
                : (_isAdmin ? "ARTICOL PUBLICAT ÎN CODEX!" : "ARTICOL TRIMIS SPRE APROBARE DE ADMIN."),
            style: TextStyle(fontWeight: clean ? FontWeight.w400 : FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: clean ? const Color(0xFF212529) : AppColors.forest,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/panou-profesor');
    } catch (e) {
      if (!mounted) return;
      if (clean) {
        setState(() => _error = 'Nu am putut salva lecția. Încearcă din nou.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("EROARE: $e"), backgroundColor: AppColors.sunset));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(builder: (context, s) => s.isClean ? _buildClean(context) : _buildRetro(context));
  }

  // ===========================================================================
  // CLEAN — split editor: form on the left, live lesson preview on the right
  // (same look as the lesson page), sections can be moved up/down, live
  // reading-time estimate. Meadow scene (same as the lesson pages).
  // ===========================================================================
  static const _subjects = ["PYTHON", "C++", "MATEMATICĂ"];
  static const _grades = ["9", "10", "11", "12"];

  Color get _sc => _selectedSubject == 'MATEMATICĂ' ? const Color(0xFFE5484D) : (_selectedSubject == 'C++' ? const Color(0xFF3B82F6) : Pb.primary);

  InputDecoration _dec(String hint) => Pb.input(hint: hint).copyWith(contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12));

  Widget _label(String t, {String? hint}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(t, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Pb.text)),
            if (hint != null) ...[const SizedBox(width: 6), Flexible(child: Text(hint, style: TextStyle(fontSize: 12.5, color: Pb.muted)))],
          ],
        ),
      );

  Widget _seg(List<String> values, String current, String Function(String) label, void Function(String) onPick) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: Pb.gray, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final v in values)
              CkHover(
                onTap: () => setState(() => onPick(v)),
                builder: (h) {
                  final sel = v == current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? Pb.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: sel ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))] : null,
                    ),
                    child: Text(label(v), style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? Pb.text : Pb.muted)),
                  );
                },
              ),
          ],
        ),
      );

  Widget _buildClean(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 1000;

    final meta = Container(
      padding: const EdgeInsets.all(20),
      decoration: ckDeco(r: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 12,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Materia'),
                _seg(_subjects, _selectedSubject, (s) => s == 'MATEMATICĂ' ? 'Matematică' : (s == 'PYTHON' ? 'Python' : s), (s) => _selectedSubject = s),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Clasa'),
                _seg(_grades, _selectedGrade, (g) => 'a $g-a', (g) => _selectedGrade = g),
              ]),
            ],
          ),
          const SizedBox(height: 14),
          _label('Capitol', hint: 'ex.: 2. Structuri de control'),
          TextFormField(
            controller: _moduleCtrl,
            style: TextStyle(fontSize: 15, color: Pb.text),
            decoration: _dec('Numărul și numele capitolului'),
            validator: (v) => v!.trim().isEmpty ? 'Scrie capitolul.' : null,
          ),
          const SizedBox(height: 14),
          _label('Titlul lecției'),
          TextFormField(
            controller: _titleCtrl,
            style: TextStyle(fontSize: 15, color: Pb.text, fontWeight: FontWeight.w600),
            decoration: _dec('Ex.: Instrucțiunea if'),
            validator: (v) => v!.trim().isEmpty ? 'Scrie un titlu.' : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _label('Rezumat', hint: 'apare pe cardul lecției')),
              Text('${_descCtrl.text.length}/160', style: TextStyle(fontSize: 12, color: _descCtrl.text.length > 160 ? const Color(0xFFE5484D) : Pb.muted)),
            ],
          ),
          TextFormField(
            controller: _descCtrl,
            maxLines: 2,
            style: TextStyle(fontSize: 14.5, color: Pb.text),
            decoration: _dec('O frază despre ce învață elevul.'),
            validator: (v) => v!.trim().isEmpty ? 'Scrie un rezumat scurt.' : null,
          ),
        ],
      ),
    );

    final sections = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _sections.length; i++) _cSectionEditor(i),
        CkHover(
          onTap: _addSection,
          builder: (h) => AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: h ? Pb.primary.withOpacity(0.06) : Pb.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: h ? Pb.primary : Pb.border, width: 1.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 18, color: h ? Pb.link : Pb.muted),
                const SizedBox(width: 6),
                Text('Adaugă o secțiune', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: h ? Pb.link : Pb.muted)),
              ],
            ),
          ),
        ),
      ],
    );

    final submit = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          PbAlert(type: PbAlertType.danger, icon: Icons.error_outline, child: Text(_error!, style: const TextStyle(fontSize: 14))),
          const SizedBox(height: 12),
        ],
        PbButton(
          text: _isAdmin ? 'Publică acum' : 'Trimite spre aprobare',
          icon: _isAdmin ? Icons.publish : Icons.send_outlined,
          fullWidth: true,
          loading: _isSaving,
          onPressed: _isSaving ? null : _submitArticle,
        ),
      ],
    );

    final editor = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [meta, const SizedBox(height: 14), sections, const SizedBox(height: 18), submit],
      ),
    );

    final stats = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in [
          (Icons.schedule, '$_readMinutes min de citit'),
          (Icons.notes, '$_words cuvinte'),
          (Icons.view_agenda_outlined, '${_sections.length} ${_sections.length == 1 ? 'secțiune' : 'secțiuni'}'),
          if (_codeLines > 0) (Icons.code, '$_codeLines linii de cod'),
        ])
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Pb.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: Pb.border)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(s.$1, size: 14, color: Pb.muted),
              const SizedBox(width: 5),
              Text(s.$2, style: TextStyle(fontSize: 12.5, color: Pb.text)),
            ]),
          ),
      ],
    );

    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            PbButton(
              text: 'Înapoi',
              icon: Icons.arrow_back,
              variant: PbVariant.outlineSecondary,
              size: PbSize.sm,
              onPressed: () => context.canPop() ? context.pop() : context.go('/panou-profesor'),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (_isAdmin ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B)).withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(_isAdmin ? 'Publicare directă (admin)' : 'Necesită aprobare',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _isAdmin ? const Color(0xFF3B82F6) : const Color(0xFFB45309))),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text('Lecție nouă', style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.w700, color: Pb.text, letterSpacing: -0.5)),
        const SizedBox(height: 10),
        stats,
        const SizedBox(height: 18),
      ],
    );

    Widget content;
    if (isMobile) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          head,
          Align(
            alignment: Alignment.centerLeft,
            child: _seg(['edit', 'preview'], _previewOnMobile ? 'preview' : 'edit', (v) => v == 'edit' ? 'Editează' : 'Previzualizare',
                (v) => _previewOnMobile = v == 'preview'),
          ),
          const SizedBox(height: 12),
          // keep the form mounted so validation still works
          Offstage(offstage: _previewOnMobile, child: editor),
          if (_previewOnMobile) _cPreview(),
          const SizedBox(height: 40),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          head,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(flex: 11, child: editor), const SizedBox(width: 18), Expanded(flex: 10, child: _cPreview())],
          ),
          const SizedBox(height: 40),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Pb.page,
      body: Column(
        children: [
          const CustomNavbar(),
          Expanded(
            child: HomeSky(
              blockers: [_mainKey],
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, isMobile ? 20 : 32, isMobile ? 12 : 24, 0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: KeyedSubtree(key: _mainKey, child: CkReveal(child: content)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cSectionEditor(int i) {
    final s = _sections[i];
    final c = _sc;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: ckDeco(r: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.withOpacity(0.13), borderRadius: BorderRadius.circular(8)),
                child: Text('${i + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: s["heading"],
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Pb.text),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Titlul secțiunii'),
                ),
              ),
              IconButton(
                tooltip: 'Mută mai sus',
                splashRadius: 16,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.arrow_upward, size: 18, color: i == 0 ? Pb.border : Pb.muted),
                onPressed: i == 0 ? null : () => _moveSection(i, -1),
              ),
              IconButton(
                tooltip: 'Mută mai jos',
                splashRadius: 16,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.arrow_downward, size: 18, color: i == _sections.length - 1 ? Pb.border : Pb.muted),
                onPressed: i == _sections.length - 1 ? null : () => _moveSection(i, 1),
              ),
              if (_sections.length > 1)
                IconButton(
                  tooltip: 'Șterge secțiunea',
                  splashRadius: 16,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE5484D)),
                  onPressed: () => _removeSection(i),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: s["text"],
            maxLines: 5,
            minLines: 3,
            style: TextStyle(fontSize: 14.5, color: Pb.text, height: 1.55),
            decoration: _dec('Explicația pentru elev…').copyWith(contentPadding: const EdgeInsets.all(12)),
            validator: (v) => v!.trim().isEmpty ? 'Scrie explicația secțiunii.' : null,
          ),
          const SizedBox(height: 10),
          _label('Cod', hint: 'opțional'),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10)),
            child: TextFormField(
              controller: s["code"],
              maxLines: 5,
              minLines: 2,
              style: const TextStyle(color: Color(0xFFD4D4D4), fontFamily: 'monospace', fontSize: 13.5, height: 1.5),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: _selectedSubject == 'PYTHON' ? 'print("Salut!")' : (_selectedSubject == 'C++' ? 'cout << "Salut!";' : 'formulă sau calcul…'),
                hintStyle: const TextStyle(color: Color(0xFF6A6A6A), fontFamily: 'monospace'),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _label('Sfat / atenție', hint: 'opțional, apare evidențiat'),
          TextFormField(
            controller: s["callout"],
            maxLines: 2,
            style: TextStyle(fontSize: 14, color: Pb.text),
            decoration: _dec('Ex.: Greșeală frecventă: uiți de „:” după if.').copyWith(
              prefixIcon: const Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFFF59E0B)),
            ),
          ),
        ],
      ),
    );
  }

  /// Renders the article the way the lesson page shows it.
  Widget _cPreview() {
    final c = _sc;
    final title = _titleCtrl.text.trim();
    final module = _moduleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final subjectLabel = _selectedSubject == 'MATEMATICĂ' ? 'Matematică' : (_selectedSubject == 'PYTHON' ? 'Python' : 'C++');

    Color calloutColor(String t) {
      final l = t.toLowerCase();
      if (l.contains('greș') || l.contains('atenț') || l.contains('capcan')) return const Color(0xFFE5484D);
      if (l.contains('sfat') || l.contains('regul') || l.contains('reține')) return const Color(0xFF10B981);
      return const Color(0xFFF59E0B);
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ckDeco(r: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 5, color: c),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 15, color: Pb.muted),
                    const SizedBox(width: 6),
                    Text('Previzualizare', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('$subjectLabel / Clasa a $_selectedGrade-a${module.isEmpty ? '' : ' / $module'}', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                const SizedBox(height: 6),
                Text(title.isEmpty ? 'Titlul lecției' : title,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: title.isEmpty ? Pb.muted : Pb.text, letterSpacing: -0.4, height: 1.2)),
                const SizedBox(height: 8),
                if (desc.isNotEmpty) Text(desc, style: TextStyle(fontSize: 14.5, color: Pb.muted, height: 1.5)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Pb.muted),
                    const SizedBox(width: 4),
                    Text('$_readMinutes min', style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: Pb.border),
                for (var i = 0; i < _sections.length; i++) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.withOpacity(0.13), borderRadius: BorderRadius.circular(8)),
                        child: Text('${i + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _sections[i]["heading"]!.text.trim().replaceFirst(RegExp(r'^\d+\.\s*'), '').isEmpty
                              ? 'Secțiune'
                              : _sections[i]["heading"]!.text.trim().replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Pb.text),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _sections[i]["text"]!.text.trim().isEmpty ? 'Explicația apare aici…' : _sections[i]["text"]!.text.trim(),
                    style: TextStyle(
                      fontSize: 14.5,
                      color: _sections[i]["text"]!.text.trim().isEmpty ? Pb.muted : Pb.text,
                      height: 1.65,
                      fontStyle: _sections[i]["text"]!.text.trim().isEmpty ? FontStyle.italic : null,
                    ),
                  ),
                  if (_sections[i]["code"]!.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10)),
                      child: Text(_sections[i]["code"]!.text, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(0xFFD4D4D4), height: 1.5)),
                    ),
                  ],
                  if (_sections[i]["callout"]!.text.trim().isNotEmpty)
                    Builder(builder: (context) {
                      final t = _sections[i]["callout"]!.text.trim();
                      final cc = calloutColor(t);
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cc.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border(left: BorderSide(color: cc, width: 3)),
                        ),
                        child: Text(t, style: TextStyle(fontSize: 14, color: Pb.text, height: 1.5)),
                      );
                    }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // RETRO — original layout
  // ===========================================================================
  Widget _buildRetro(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text("CONTRIBUTE TO CODEX", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.ink),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(2.5), child: Container(color: AppColors.border, height: 2.5)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.mustard, border: Border.all(color: AppColors.border, width: 2)),
                    child: Text(
                      _isAdmin ? "ADMIN PUBLISHING PROTOCOL ACTIVE (INSTANT PUBLISH)" : "TEACHER SUBMISSION (REQUIRES ADMIN REVIEW)",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSubject,
                          decoration: _inputDecoration("DISCIPLINE"),
                          dropdownColor: AppColors.cardBg,
                          items: _subjects
                              .map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold))))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedSubject = val!),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedGrade,
                          decoration: _inputDecoration("CLASA"),
                          dropdownColor: AppColors.cardBg,
                          items: _grades
                              .map((g) => DropdownMenuItem(value: g, child: Text("CLASA A $g-A", style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold))))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedGrade = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _moduleCtrl,
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                    decoration: _inputDecoration("CAPITOL / MODUL (EX: 2. STRUCTURI DE CONTROL)"),
                    validator: (v) => v!.isEmpty ? "CAMP OBLIGATORIU" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleCtrl,
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                    decoration: _inputDecoration("TITLU ARTICOL"),
                    validator: (v) => v!.isEmpty ? "CAMP OBLIGATORIU" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 2,
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                    decoration: _inputDecoration("REZUMAT SCURT PENTRU CARD"),
                    validator: (v) => v!.isEmpty ? "CAMP OBLIGATORIU" : null,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("SECȚIUNI LECȚIE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.ink)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        onPressed: _addSection,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("ADAUGA SECȚIUNE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(_sections.length, (index) {
                    final sec = _sections[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.cloud, border: Border.all(color: AppColors.border, width: 2)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: sec["heading"],
                                  style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink),
                                  decoration: _inputDecoration("TITLU SECȚIUNE"),
                                ),
                              ),
                              if (_sections.length > 1) ...[
                                const SizedBox(width: 8),
                                IconButton(icon: Icon(Icons.delete, color: AppColors.sunset), onPressed: () => _removeSection(index)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: sec["text"],
                            maxLines: 4,
                            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
                            decoration: _inputDecoration("TEXT EXPLICAȚIE"),
                            validator: (v) => v!.isEmpty ? "TEXTUL NU POATE FI GOL" : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: sec["code"],
                            maxLines: 4,
                            style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF55EFC4), fontWeight: FontWeight.bold),
                            decoration: _inputDecoration("EXEMPLU DE COD (OPȚIONAL)").copyWith(fillColor: const Color(0xFF1B242B)),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: sec["callout"],
                            maxLines: 2,
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.sunset),
                            decoration: _inputDecoration("CALLOUT / SFAT DE COD (OPȚIONAL)"),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: _isSaving ? null : _submitArticle,
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_isAdmin ? "PUBLICĂ IMEDIAT" : "TRIMITE SPRE APROBARE",
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 12),
      filled: true,
      fillColor: AppColors.inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sky, width: 2.5)),
    );
  }
}
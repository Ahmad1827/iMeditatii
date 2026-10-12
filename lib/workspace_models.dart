import 'dart:convert';
import 'dart:ui' show Offset;

import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// ATELIER — data model.
//
// workspace_docs/{id}      a teacher's own notebook page or code file
// workspace_shares/{id}    a copy sent to one student (id = "<docId>_<studentId>")
//
// A share is a snapshot: editing the original does not change what the student
// has until the teacher sends it again.
// =============================================================================

// ----------------------------------------------------------------- note blocks
class NoteStroke {
  final int color; // ARGB
  final double width; // relative to canvas width
  final bool marker; // highlighter: wide + translucent
  final List<Offset> points; // normalised by canvas width

  NoteStroke({required this.color, required this.width, this.marker = false, List<Offset>? points})
      : points = points ?? <Offset>[];

  Map<String, dynamic> toJson() => {
        'c': color,
        'w': _r(width),
        if (marker) 'm': 1,
        'p': [for (final p in points) ...[_r(p.dx), _r(p.dy)]],
      };

  static NoteStroke fromJson(Map<String, dynamic> j) {
    final raw = (j['p'] as List?) ?? const [];
    final pts = <Offset>[];
    for (var i = 0; i + 1 < raw.length; i += 2) {
      pts.add(Offset((raw[i] as num).toDouble(), (raw[i + 1] as num).toDouble()));
    }
    return NoteStroke(
      color: (j['c'] as num?)?.toInt() ?? 0xFF262626,
      width: (j['w'] as num?)?.toDouble() ?? 0.004,
      marker: j['m'] == 1,
      points: pts,
    );
  }

  static double _r(double v) => (v * 10000).roundToDouble() / 10000;
}

class NoteBlock {
  static const String p = 'p';
  static const String h1 = 'h1';
  static const String h2 = 'h2';
  static const String bullet = 'bullet';
  static const String numbered = 'num';
  static const String todo = 'todo';
  static const String quote = 'quote';
  static const String callout = 'callout';
  static const String code = 'code';
  static const String draw = 'draw';
  static const String divider = 'divider';

  static const Map<String, String> labels = {
    p: 'Text',
    h1: 'Titlu',
    h2: 'Subtitlu',
    bullet: 'Listă',
    numbered: 'Listă numerotată',
    todo: 'De făcut',
    quote: 'Citat',
    callout: 'Reține',
    code: 'Cod',
    draw: 'Desen',
    divider: 'Linie',
  };

  static int _seq = 0;
  static String newId() => '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(_seq++).toRadixString(36)}';

  final String id;
  String type;
  String text;
  bool checked;
  String lang; // code blocks
  double ratio; // draw blocks: height / width
  String paper; // draw blocks: blank | grid | lines
  List<NoteStroke> strokes;

  NoteBlock({
    String? id,
    this.type = p,
    this.text = '',
    this.checked = false,
    this.lang = 'cpp',
    this.ratio = 0.42,
    this.paper = 'blank',
    List<NoteStroke>? strokes,
  })  : id = id ?? newId(),
        strokes = strokes ?? <NoteStroke>[];

  bool get hasText => type != draw && type != divider;
  bool get isList => type == bullet || type == numbered || type == todo;

  Map<String, dynamic> toJson() => {
        'id': id,
        't': type,
        if (hasText) 'x': text,
        if (type == todo && checked) 'c': 1,
        if (type == code) 'l': lang,
        if (type == draw) ...{
          'r': ratio,
          'bg': paper,
          's': [for (final s in strokes) s.toJson()],
        },
      };

  static NoteBlock fromJson(Map<String, dynamic> j) => NoteBlock(
        id: j['id'] as String?,
        type: labels.containsKey(j['t']) ? j['t'] as String : p,
        text: '${j['x'] ?? ''}',
        checked: j['c'] == 1,
        lang: '${j['l'] ?? 'cpp'}',
        ratio: (j['r'] as num?)?.toDouble() ?? 0.42,
        paper: '${j['bg'] ?? 'blank'}',
        strokes: [
          for (final s in (j['s'] as List?) ?? const [])
            if (s is Map) NoteStroke.fromJson(Map<String, dynamic>.from(s)),
        ],
      );

  NoteBlock copy() => fromJson(toJson()..remove('id'));
}

class NoteContent {
  /// Firestore documents are capped at 1 MiB; leave room for the other fields.
  static const int maxLength = 900000;

  static List<NoteBlock> parse(String raw) {
    if (raw.trim().isEmpty) return [NoteBlock()];
    try {
      final j = jsonDecode(raw);
      final list = (j is Map ? j['blocks'] : j) as List? ?? const [];
      final blocks = [
        for (final b in list)
          if (b is Map) NoteBlock.fromJson(Map<String, dynamic>.from(b)),
      ];
      return blocks.isEmpty ? [NoteBlock()] : blocks;
    } catch (_) {
      // Not JSON: treat as plain text, one paragraph per line.
      return [for (final line in raw.split('\n')) NoteBlock(text: line)];
    }
  }

  static String encode(List<NoteBlock> blocks) => jsonEncode({
        'v': 1,
        'blocks': [for (final b in blocks) b.toJson()],
      });

  static String fromBlocks(List<NoteBlock> blocks) => encode(blocks);

  /// First non-empty lines, for list previews.
  static String preview(String raw, {int max = 140}) {
    final out = StringBuffer();
    for (final b in parse(raw)) {
      if (!b.hasText || b.text.trim().isEmpty) continue;
      if (out.isNotEmpty) out.write(' · ');
      out.write(b.text.trim().replaceAll(RegExp(r'\*\*|==|~~|`'), '').replaceAll('\n', ' '));
      if (out.length >= max) break;
    }
    final s = out.toString();
    return s.length > max ? '${s.substring(0, max)}…' : s;
  }
}

// ----------------------------------------------------------------- documents
class WsDoc {
  static const String note = 'note';
  static const String code = 'code';

  final String id;
  final String ownerId;
  final String type;
  final String title;
  final String content;
  final String lang;
  final String stdin;
  final String section;
  final bool pinned;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WsDoc({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.title,
    required this.content,
    this.lang = 'cpp',
    this.stdin = '',
    this.section = '',
    this.pinned = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get isCode => type == code;
  String get displayTitle => title.trim().isEmpty ? (isCode ? 'Fișier fără nume' : 'Pagină fără titlu') : title.trim();
  String get langLabel => lang == 'python' ? 'Python' : 'C++';

  static WsDoc fromSnap(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    return WsDoc(
      id: d.id,
      ownerId: '${m['ownerId'] ?? ''}',
      type: m['type'] == code ? code : note,
      title: '${m['title'] ?? ''}',
      content: '${m['content'] ?? ''}',
      lang: m['lang'] == 'python' ? 'python' : 'cpp',
      stdin: '${m['stdin'] ?? ''}',
      section: '${m['section'] ?? ''}',
      pinned: m['pinned'] == true,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class WsShare {
  final String id;
  final String docId;
  final String type;
  final String title;
  final String content;
  final String lang;
  final String stdin;
  final String teacherId;
  final String teacherName;
  final String studentId;
  final String studentName;
  final String message;
  final int version;
  final DateTime? sentAt;
  final DateTime? seenAt;
  final String? studentContent; // the student's own working copy (code) — null until they edit
  final DateTime? studentUpdatedAt;
  final Map<String, bool> checks; // note checklists ticked by the student

  const WsShare({
    required this.id,
    required this.docId,
    required this.type,
    required this.title,
    required this.content,
    required this.lang,
    required this.stdin,
    required this.teacherId,
    required this.teacherName,
    required this.studentId,
    required this.studentName,
    required this.message,
    required this.version,
    this.sentAt,
    this.seenAt,
    this.studentContent,
    this.studentUpdatedAt,
    this.checks = const {},
  });

  bool get isCode => type == WsDoc.code;
  bool get seen => seenAt != null;
  bool get studentEdited => studentContent != null && studentContent != content;
  String get displayTitle => title.trim().isEmpty ? (isCode ? 'Fișier fără nume' : 'Pagină fără titlu') : title.trim();
  String get langLabel => lang == 'python' ? 'Python' : 'C++';

  static WsShare fromSnap(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    return WsShare(
      id: d.id,
      docId: '${m['docId'] ?? ''}',
      type: m['type'] == WsDoc.code ? WsDoc.code : WsDoc.note,
      title: '${m['title'] ?? ''}',
      content: '${m['content'] ?? ''}',
      lang: m['lang'] == 'python' ? 'python' : 'cpp',
      stdin: '${m['stdin'] ?? ''}',
      teacherId: '${m['teacherId'] ?? ''}',
      teacherName: '${m['teacherName'] ?? 'Profesor'}',
      studentId: '${m['studentId'] ?? ''}',
      studentName: '${m['studentName'] ?? 'Elev'}',
      message: '${m['message'] ?? ''}',
      version: (m['version'] as num?)?.toInt() ?? 1,
      sentAt: (m['sentAt'] as Timestamp?)?.toDate(),
      seenAt: (m['seenAt'] as Timestamp?)?.toDate(),
      studentContent: m['studentContent'] as String?,
      studentUpdatedAt: (m['studentUpdatedAt'] as Timestamp?)?.toDate(),
      checks: {
        for (final e in ((m['checks'] as Map?) ?? const {}).entries) '${e.key}': e.value == true,
      },
    );
  }
}

/// A student the teacher can send to (taken from their conversations).
class WsStudent {
  final String id;
  final String name;
  final String chatId;
  const WsStudent({required this.id, required this.name, required this.chatId});
}

// ----------------------------------------------------------------- service
class Workspace {
  /// Set by tests to run against an in-memory database.
  static FirebaseFirestore? overrideDb;
  static FirebaseFirestore get _db => overrideDb ?? FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get docs => _db.collection('workspace_docs');
  static CollectionReference<Map<String, dynamic>> get shares => _db.collection('workspace_shares');

  static int _byRecent(DateTime? a, DateTime? b) =>
      (b ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a ?? DateTime.fromMillisecondsSinceEpoch(0));

  // Single-field filters only, sorted on the client, so no composite index is needed.
  static Stream<List<WsDoc>> myDocs(String uid) => docs.where('ownerId', isEqualTo: uid).snapshots().map((s) {
        final list = s.docs.map(WsDoc.fromSnap).toList();
        // A just-written doc has a null server timestamp until the write is acknowledged: keep it on top.
        list.sort((a, b) => _byRecent(a.updatedAt ?? DateTime.now(), b.updatedAt ?? DateTime.now()));
        return list;
      });

  static Stream<List<WsShare>> sentBy(String teacherId) =>
      shares.where('teacherId', isEqualTo: teacherId).snapshots().map((s) {
        final list = s.docs.map(WsShare.fromSnap).toList();
        list.sort((a, b) => _byRecent(a.sentAt ?? DateTime.now(), b.sentAt ?? DateTime.now()));
        return list;
      });

  static Stream<List<WsShare>> receivedBy(String studentId) =>
      shares.where('studentId', isEqualTo: studentId).snapshots().map((s) {
        final list = s.docs.map(WsShare.fromSnap).toList();
        list.sort((a, b) => _byRecent(a.sentAt ?? DateTime.now(), b.sentAt ?? DateTime.now()));
        return list;
      });

  static Future<List<WsStudent>> studentsOf(String teacherId) async {
    final snap = await _db.collection('chats').where('teacherId', isEqualTo: teacherId).get();
    final seen = <String>{};
    final out = <WsStudent>[];
    for (final d in snap.docs) {
      final m = d.data();
      final id = '${m['studentId'] ?? ''}';
      if (id.isEmpty || !seen.add(id)) continue;
      out.add(WsStudent(id: id, name: '${m['studentName'] ?? 'Elev'}', chatId: d.id));
    }
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  static Future<String> teacherName(String uid) async {
    final d = await _db.collection('teachers').doc(uid).get();
    final n = '${d.data()?['name'] ?? ''}'.trim();
    return n.isEmpty ? 'Profesor' : n;
  }

  static Future<String> create({
    required String ownerId,
    required String type,
    String title = '',
    String content = '',
    String lang = 'cpp',
    String stdin = '',
    String section = '',
  }) async {
    final ref = docs.doc();
    await ref.set({
      'ownerId': ownerId,
      'type': type,
      'title': title,
      'content': content,
      'lang': lang,
      'stdin': stdin,
      'section': section,
      'pinned': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> update(String id, Map<String, dynamic> fields, {bool touch = true}) =>
      docs.doc(id).update({...fields, if (touch) 'updatedAt': FieldValue.serverTimestamp()});

  static Future<void> delete(String id) => docs.doc(id).delete();

  static String shareId(String docId, String studentId) => '${docId}_$studentId';

  /// Sends the current state of a document to each student and drops a line in
  /// their conversation so they get notified the usual way.
  static Future<void> send({
    required String docId,
    required String type,
    required String title,
    required String content,
    required String lang,
    required String stdin,
    required String teacherId,
    required String teacherName,
    required List<WsStudent> students,
    String message = '',
  }) async {
    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();
    for (final s in students) {
      batch.set(
        shares.doc(shareId(docId, s.id)),
        {
          'docId': docId,
          'type': type,
          'title': title,
          'content': content,
          'lang': lang,
          'stdin': stdin,
          'teacherId': teacherId,
          'teacherName': teacherName,
          'studentId': s.id,
          'studentName': s.name,
          'message': message,
          'sentAt': now,
          'seenAt': null,
          'version': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();

    final label = title.trim().isEmpty ? (type == WsDoc.code ? 'un fișier de cod' : 'o pagină de notițe') : '„${title.trim()}”';
    final text = message.trim().isEmpty
        ? 'Ți-am trimis $label. Îl găsești în panoul tău, la Materiale primite.'
        : 'Ți-am trimis $label: ${message.trim()}';
    for (final s in students) {
      if (s.chatId.isEmpty) continue;
      try {
        final chat = _db.collection('chats').doc(s.chatId);
        await chat.collection('messages').add({
          'senderId': teacherId,
          'text': text,
          'createdAt': Timestamp.now(),
          'isRead': false,
        });
        await chat.set({'lastMessage': text, 'updatedAt': Timestamp.now()}, SetOptions(merge: true));
      } catch (_) {
        // The material itself was delivered; the chat line is a courtesy.
      }
    }
  }

  static Future<void> unsend(String shareId) => shares.doc(shareId).delete();

  static Future<void> markSeen(String shareId) => shares.doc(shareId).update({'seenAt': FieldValue.serverTimestamp()});

  static Future<void> saveStudentCopy(String shareId, String? code) => shares.doc(shareId).update({
        'studentContent': code,
        'studentUpdatedAt': FieldValue.serverTimestamp(),
      });

  static Future<void> saveCheck(String shareId, String blockId, bool value) =>
      shares.doc(shareId).update({'checks.$blockId': value});
}

// ----------------------------------------------------------------- templates
class WsTemplate {
  final String name;
  final String desc;
  final String type;
  final String title;
  final String lang;
  final String stdin;
  final String Function() build;
  const WsTemplate({
    required this.name,
    required this.desc,
    required this.type,
    required this.title,
    required this.build,
    this.lang = 'cpp',
    this.stdin = '',
  });

  static String _note(List<NoteBlock> b) => NoteContent.encode(b);

  static final List<WsTemplate> all = [
    WsTemplate(
      name: 'Pagină goală',
      desc: 'Începi de la zero.',
      type: WsDoc.note,
      title: '',
      build: () => _note([NoteBlock()]),
    ),
    WsTemplate(
      name: 'Plan de lecție',
      desc: 'Obiective, teorie, exemple, temă.',
      type: WsDoc.note,
      title: 'Plan de lecție',
      build: () => _note([
        NoteBlock(type: NoteBlock.h2, text: 'Obiective'),
        NoteBlock(type: NoteBlock.bullet, text: ''),
        NoteBlock(type: NoteBlock.h2, text: 'Teorie'),
        NoteBlock(text: ''),
        NoteBlock(type: NoteBlock.callout, text: 'Ideea de reținut din lecția asta.'),
        NoteBlock(type: NoteBlock.h2, text: 'Exemple rezolvate'),
        NoteBlock(type: NoteBlock.numbered, text: ''),
        NoteBlock(type: NoteBlock.draw),
        NoteBlock(type: NoteBlock.h2, text: 'Temă'),
        NoteBlock(type: NoteBlock.todo, text: ''),
      ]),
    ),
    WsTemplate(
      name: 'Fișă de lucru',
      desc: 'Exerciții cu spațiu de rezolvare.',
      type: WsDoc.note,
      title: 'Fișă de lucru',
      build: () => _note([
        NoteBlock(text: 'Rezolvă exercițiile de mai jos. Bifează-le pe măsură ce le termini.'),
        NoteBlock(type: NoteBlock.todo, text: 'Exercițiul 1: '),
        NoteBlock(type: NoteBlock.draw, paper: 'grid', ratio: 0.28),
        NoteBlock(type: NoteBlock.todo, text: 'Exercițiul 2: '),
        NoteBlock(type: NoteBlock.draw, paper: 'grid', ratio: 0.28),
        NoteBlock(type: NoteBlock.todo, text: 'Exercițiul 3: '),
        NoteBlock(type: NoteBlock.draw, paper: 'grid', ratio: 0.28),
      ]),
    ),
    WsTemplate(
      name: 'Schelet C++',
      desc: 'Citire, prelucrare, afișare.',
      type: WsDoc.code,
      title: 'main.cpp',
      stdin: '5\n3 1 4 1 5\n',
      build: () => '#include <iostream>\n'
          '#include <vector>\n'
          'using namespace std;\n\n'
          'int main() {\n'
          '    int n;\n'
          '    cin >> n;\n'
          '    vector<int> v(n);\n'
          '    for (int i = 0; i < n; i++) {\n'
          '        cin >> v[i];\n'
          '    }\n\n'
          '    long long suma = 0;\n'
          '    for (int x : v) {\n'
          '        suma += x;\n'
          '    }\n'
          '    cout << suma << "\\n";\n'
          '    return 0;\n'
          '}\n',
    ),
    WsTemplate(
      name: 'Schelet Python',
      desc: 'Citire de la tastatură și afișare.',
      type: WsDoc.code,
      title: 'main.py',
      lang: 'python',
      stdin: '5\n3 1 4 1 5\n',
      build: () => 'n = int(input())\n'
          'v = list(map(int, input().split()))\n\n'
          'suma = 0\n'
          'for x in v:\n'
          '    suma += x\n\n'
          'print(suma)\n',
    ),
  ];
}

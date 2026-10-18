import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'workspace_models.dart';

// =============================================================================
// CLASSES & HOMEWORK — data model.
//
// classes/{code}     a teacher's class; the id is the short code in the invite
//                    link (/clasa/K7M2QX). Students join by opening the link.
// homework/{id}      one assignment, sent to whole classes (classIds) and/or to
//                    single students (studentIds). Students who join a class
//                    later still see the class's homework.
//
// Per-student state lives on the homework doc, keyed by student id:
//   done.{uid}    when they marked it finished
//   hidden.{uid}  they dismissed it from the floating dock (still on /clase)
// =============================================================================

class ClassMember {
  final String id;
  final String name;
  final DateTime? joinedAt;
  const ClassMember({required this.id, required this.name, this.joinedAt});
}

class SchoolClass {
  final String id; // = invite code
  final String name;
  final String subject;
  final String teacherId;
  final String teacherName;
  final List<ClassMember> members;
  final Map<String, int> seats; // uid -> chair the student picked
  final DateTime? createdAt;

  const SchoolClass({
    required this.id,
    required this.name,
    required this.subject,
    required this.teacherId,
    required this.teacherName,
    required this.members,
    this.seats = const {},
    this.createdAt,
  });

  String get displayName => name.trim().isEmpty ? 'Clasă fără nume' : name.trim();
  String get path => '/clasa/$id';
  bool hasMember(String uid) => members.any((m) => m.id == uid);

  static SchoolClass fromSnap(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    final raw = (m['members'] as Map?) ?? const {};
    final members = <ClassMember>[
      for (final e in raw.entries)
        if (e.value is Map)
          ClassMember(
            id: '${e.key}',
            name: '${(e.value as Map)['name'] ?? 'Elev'}',
            joinedAt: ((e.value as Map)['joinedAt'] as Timestamp?)?.toDate(),
          ),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return SchoolClass(
      id: d.id,
      name: '${m['name'] ?? ''}',
      subject: '${m['subject'] ?? ''}',
      teacherId: '${m['teacherId'] ?? ''}',
      teacherName: '${m['teacherName'] ?? 'Profesor'}',
      members: members,
      seats: {
        for (final e in ((m['seats'] as Map?) ?? const {}).entries)
          if (e.value is num && raw.containsKey(e.key)) '${e.key}': (e.value as num).toInt(),
      },
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// A problem from the problem bank attached to a homework.
class HwProblem {
  final String id;
  final String title;
  final String subject;
  final String grade;
  const HwProblem({required this.id, required this.title, required this.subject, required this.grade});

  String get path => '/exercitiu/$id?materie=${Uri.encodeComponent(subject)}&clasa=${Uri.encodeComponent(grade)}';

  /// The key the problem page saves in `users/{uid}.solvedIds` once solved.
  String get progressKey => '${subject}_${grade}_$id';

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'subject': subject, 'grade': grade};
  static HwProblem fromJson(Map j) => HwProblem(
        id: '${j['id'] ?? ''}',
        title: '${j['title'] ?? ''}',
        subject: '${j['subject'] ?? ''}',
        grade: '${j['grade'] ?? ''}',
      );
}

/// An Atelier document attached to a homework. Each student gets their own
/// copy the first time they open it (see [Classes.openMaterial]).
class HwMaterial {
  final String docId;
  final String type;
  final String title;
  final String lang;
  const HwMaterial({required this.docId, required this.type, required this.title, required this.lang});

  String get displayTitle =>
      title.trim().isEmpty ? (type == WsDoc.code ? 'Fișier fără nume' : 'Pagină fără titlu') : title.trim();

  Map<String, dynamic> toJson() => {'docId': docId, 'type': type, 'title': title, 'lang': lang};
  static HwMaterial fromJson(Map j) => HwMaterial(
        docId: '${j['docId'] ?? ''}',
        type: WsDoc.typeOf(j['type']),
        title: '${j['title'] ?? ''}',
        lang: j['lang'] == 'python' ? 'python' : 'cpp',
      );
}

class Homework {
  final String id;
  final String teacherId;
  final String teacherName;
  final String title;
  final String instructions;
  final DateTime? dueAt;
  final DateTime? createdAt;
  final List<String> classIds;
  final Map<String, String> classNames; // classId -> name, for display
  final List<String> studentIds;
  final Map<String, String> studentNames; // direct recipients
  final List<HwProblem> problems;
  final HwMaterial? material;
  final Map<String, DateTime?> done;
  final Set<String> hidden;

  const Homework({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.title,
    required this.instructions,
    this.dueAt,
    this.createdAt,
    this.classIds = const [],
    this.classNames = const {},
    this.studentIds = const [],
    this.studentNames = const {},
    this.problems = const [],
    this.material,
    this.done = const {},
    this.hidden = const {},
  });

  String get displayTitle => title.trim().isEmpty ? 'Temă' : title.trim();
  bool isDone(String uid) => done.containsKey(uid);
  bool isHidden(String uid) => hidden.contains(uid);
  bool get overdue => dueAt != null && dueAt!.isBefore(DateTime.now());

  /// Who it was sent to, in words: "9B, Andrei Pop".
  String get audience => [
        for (final c in classIds) classNames[c] ?? c,
        for (final s in studentIds) studentNames[s] ?? 'Elev',
      ].join(', ');

  static Homework fromSnap(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    Map<String, String> strMap(dynamic v) => {for (final e in ((v as Map?) ?? const {}).entries) '${e.key}': '${e.value}'};
    return Homework(
      id: d.id,
      teacherId: '${m['teacherId'] ?? ''}',
      teacherName: '${m['teacherName'] ?? 'Profesor'}',
      title: '${m['title'] ?? ''}',
      instructions: '${m['instructions'] ?? ''}',
      dueAt: (m['dueAt'] as Timestamp?)?.toDate(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      classIds: [for (final c in (m['classIds'] as List?) ?? const []) '$c'],
      classNames: strMap(m['classNames']),
      studentIds: [for (final s in (m['studentIds'] as List?) ?? const []) '$s'],
      studentNames: strMap(m['studentNames']),
      problems: [
        for (final p in (m['problems'] as List?) ?? const [])
          if (p is Map) HwProblem.fromJson(p),
      ],
      material: m['material'] is Map ? HwMaterial.fromJson(m['material'] as Map) : null,
      done: {
        for (final e in ((m['done'] as Map?) ?? const {}).entries)
          if (e.value != null && e.value != false) '${e.key}': e.value is Timestamp ? (e.value as Timestamp).toDate() : null,
      },
      hidden: {
        for (final e in ((m['hidden'] as Map?) ?? const {}).entries)
          if (e.value == true) '${e.key}',
      },
    );
  }
}

/// Someone homework can be sent to directly.
class HwStudent {
  final String id;
  final String name;
  const HwStudent(this.id, this.name);
}

// ----------------------------------------------------------------- service
class Classes {
  /// Set by tests to run against an in-memory database.
  static FirebaseFirestore? overrideDb;
  static FirebaseFirestore get _db => overrideDb ?? FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get classes => _db.collection('classes');
  static CollectionReference<Map<String, dynamic>> get homework => _db.collection('homework');

  // No 0/O, 1/I/L: the code is read aloud and typed by hand.
  static const String _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static final Random _rnd = Random.secure();
  static String newCode() => List.generate(6, (_) => _alphabet[_rnd.nextInt(_alphabet.length)]).join();

  /// Normalises what someone typed ("k7m-2qx ") into a code.
  static String cleanCode(String s) => s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static int _byNewest(DateTime? a, DateTime? b) =>
      (b ?? DateTime.now()).compareTo(a ?? DateTime.now());

  // ---- classes
  static Stream<List<SchoolClass>> taughtBy(String teacherId) =>
      classes.where('teacherId', isEqualTo: teacherId).snapshots().map((s) {
        final list = s.docs.map(SchoolClass.fromSnap).toList();
        list.sort((a, b) => _byNewest(a.createdAt, b.createdAt));
        return list;
      });

  static Stream<List<SchoolClass>> joinedBy(String studentId) =>
      classes.where('memberIds', arrayContains: studentId).snapshots().map((s) {
        final list = s.docs.map(SchoolClass.fromSnap).toList();
        list.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
        return list;
      });

  static Stream<SchoolClass?> watch(String code) =>
      classes.doc(code).snapshots().map((d) => d.exists ? SchoolClass.fromSnap(d) : null);

  static Future<String> create({
    required String teacherId,
    required String teacherName,
    required String name,
    String subject = '',
  }) async {
    for (var attempt = 0; attempt < 6; attempt++) {
      final code = newCode();
      final ref = classes.doc(code);
      if ((await ref.get()).exists) continue;
      await ref.set({
        'teacherId': teacherId,
        'teacherName': teacherName,
        'name': name.trim(),
        'subject': subject.trim(),
        'members': <String, dynamic>{},
        'memberIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
      return code;
    }
    throw StateError('Nu am găsit un cod liber.');
  }

  static Future<void> rename(String code, String name, String subject) =>
      classes.doc(code).update({'name': name.trim(), 'subject': subject.trim()});

  static Future<void> deleteClass(String code) => classes.doc(code).delete();

  static Future<void> join(String code, String uid, String name) => classes.doc(code).update({
        'memberIds': FieldValue.arrayUnion([uid]),
        'members.$uid': {'name': name.trim().isEmpty ? 'Elev' : name.trim(), 'joinedAt': FieldValue.serverTimestamp()},
      });

  static Future<void> removeMember(String code, String uid) => classes.doc(code).update({
        'memberIds': FieldValue.arrayRemove([uid]),
        'members.$uid': FieldValue.delete(),
        'seats.$uid': FieldValue.delete(),
      });

  /// Sits the student on chair [seat]. Fails if someone else picked it first.
  static Future<void> takeSeat(String code, String uid, int seat) => _db.runTransaction((tx) async {
        final ref = classes.doc(code);
        final c = SchoolClass.fromSnap(await tx.get(ref));
        if (c.seats.entries.any((e) => e.value == seat && e.key != uid)) throw StateError('Locul tocmai a fost ocupat.');
        tx.update(ref, {'seats.$uid': seat});
      });

  // ---- homework
  static Stream<List<Homework>> assignedBy(String teacherId) =>
      homework.where('teacherId', isEqualTo: teacherId).snapshots().map((s) {
        final list = s.docs.map(Homework.fromSnap).toList();
        list.sort((a, b) => _byNewest(a.createdAt, b.createdAt));
        return list;
      });

  static Stream<List<Homework>> forClass(String code) =>
      homework.where('classIds', arrayContains: code).snapshots().map((s) {
        final list = s.docs.map(Homework.fromSnap).toList();
        list.sort((a, b) => _byNewest(a.createdAt, b.createdAt));
        return list;
      });

  /// Everything a student has to do: homework of every class they are in plus
  /// what was sent to them by name. Two single-field queries, merged here.
  static Stream<List<Homework>> forStudent(String uid) {
    final merge = _Merge(
      direct: homework.where('studentIds', arrayContains: uid).snapshots(),
      classes: joinedBy(uid),
      byClasses: (ids) => homework.where('classIds', arrayContainsAny: ids).snapshots(),
    );
    return merge.stream;
  }

  static Future<String> assign({
    required String teacherId,
    required String teacherName,
    required String title,
    String instructions = '',
    DateTime? dueAt,
    List<SchoolClass> toClasses = const [],
    List<HwStudent> toStudents = const [],
    List<HwProblem> problems = const [],
    HwMaterial? material,
  }) async {
    final ref = homework.doc();
    await ref.set({
      'teacherId': teacherId,
      'teacherName': teacherName,
      'title': title.trim(),
      'instructions': instructions.trim(),
      'dueAt': dueAt == null ? null : Timestamp.fromDate(dueAt),
      'classIds': [for (final c in toClasses) c.id],
      'classNames': {for (final c in toClasses) c.id: c.displayName},
      'studentIds': [for (final s in toStudents) s.id],
      'studentNames': {for (final s in toStudents) s.id: s.name},
      'problems': [for (final p in problems) p.toJson()],
      'material': material?.toJson(),
      'done': <String, dynamic>{},
      'hidden': <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> deleteHomework(String id) => homework.doc(id).delete();

  static Future<void> setDone(String id, String uid, bool done) =>
      homework.doc(id).update({'done.$uid': done ? FieldValue.serverTimestamp() : FieldValue.delete()});

  /// The problems a student has solved, as [HwProblem.progressKey]s.
  static Stream<Set<String>> solvedBy(String uid) => _db.collection('users').doc(uid).snapshots().map(
        (d) => {for (final k in (d.data()?['solvedIds'] as List?) ?? const []) '$k'},
      );

  static CollectionReference<Map<String, dynamic>> get solutions => _db.collection('solutions');

  /// One document per student and problem, so the teacher can read what was
  /// sent: the last attempt, and the last one that passed.
  static String solutionId(String uid, String key) => '${uid}__${key.replaceAll('/', '_')}';

  /// Saves what the student sent on a problem page: code (C++) or an answer
  /// ([lang] null). Saved on every check, passed or not. It goes to the
  /// teachers whose homework has this problem: their ids in `teachers` (only
  /// they and the student can read it), each homework's deadline in `hw`.
  static Future<void> saveSolution({required String uid, required String key, required String text, String? lang, required bool passed}) async {
    await solutions.doc(solutionId(uid, key)).set({
      'uid': uid,
      'key': key,
      'last': text,
      'lastLang': lang,
      'lastPassed': passed,
      'lastAt': FieldValue.serverTimestamp(),
      if (passed) ...{'passed': text, 'passedLang': lang, 'passedAt': FieldValue.serverTimestamp()},
      ...await _recipients(uid, key),
    }, SetOptions(merge: true));
  }

  /// The teachers whose homework for [uid] has the problem [key], and those homework's deadlines.
  static Future<Map<String, dynamic>> _recipients(String uid, String key) async {
    final given = [
      for (final h in await forStudent(uid).first)
        if (h.problems.any((p) => p.progressKey == key)) h,
    ];
    return {
      if (given.isNotEmpty) 'teachers': FieldValue.arrayUnion([for (final h in given) h.teacherId]),
      if (given.isNotEmpty) 'hw': {for (final h in given) h.id: {'teacher': h.teacherId, 'due': h.dueAt == null ? null : Timestamp.fromDate(h.dueAt!)}},
    };
  }

  /// A maths solution written on a sheet ([sheet]: an ink page) and/or on
  /// paper ([photos]: links to its pictures), sent to be checked by a person:
  /// the admin, or a teacher whose homework has it. The page is stored once (a
  /// sheet can be large); sending again puts it back in the queue.
  static Future<void> saveSheet({
    required String uid,
    required String studentName,
    required HwProblem problem,
    required String sheet,
    List<String> photos = const [],
  }) async {
    final doc = solutions.doc(solutionId(uid, problem.progressKey));
    final attempt = doc.collection('attempts').doc();
    final sent = {
      'uid': uid,
      'key': problem.progressKey,
      'last': sheet,
      'photos': photos,
      'lastLang': Solution.sheet,
      'lastAt': FieldValue.serverTimestamp(),
      'review': 'pending',
    };
    await doc.set({
      ...sent,
      'lastPassed': false,
      'attempt': attempt.id,
      'reviewNote': '',
      'studentName': studentName,
      'exercise': problem.toJson(),
      ...await _recipients(uid, problem.progressKey),
    }, SetOptions(merge: true));
    // every one sent is kept, for the student's history; sending itself
    // doesn't hang on it
    await attempt.set(sent).catchError((_) {});
  }

  /// Every solution [uid] sent on [key], newest first, each with its own verdict.
  static Stream<List<Solution>> attempts(String uid, String key) => solutions
      .doc(solutionId(uid, key))
      .collection('attempts')
      .orderBy('lastAt', descending: true)
      .snapshots()
      .map((q) => q.docs.map((d) => Solution.fromJson(d.data())).toList());

  /// The admin's queue: every sheet waiting to be checked, oldest first.
  static Stream<List<Solution>> pendingSheets() => solutions.where('review', isEqualTo: 'pending').snapshots().map((q) {
        final list = q.docs.map((d) => Solution.fromJson(d.data())).toList();
        list.sort((a, b) => (a.lastAt ?? DateTime(3000)).compareTo(b.lastAt ?? DateTime(3000)));
        return list;
      });

  /// What a student sent themselves, by problem key.
  static Stream<Map<String, Solution>> mySolutions(String uid) => solutions.where('uid', isEqualTo: uid).snapshots().map(
        (q) => {for (final d in q.docs) '${d.data()['key'] ?? ''}': Solution.fromJson(d.data())},
      );

  /// The green light, or not, on a sheet. Accepted, the problem counts as
  /// solved for the student; turned down after being accepted, it no longer does.
  static Future<void> reviewSheet({
    required String uid,
    required String key,
    required bool accept,
    String note = '',
    required String reviewerId,
    required String reviewerName,
  }) async {
    final ref = solutions.doc(solutionId(uid, key));
    final data = (await ref.get()).data();
    final before = data?['review'];
    final verdict = {
      'review': accept ? 'approved' : 'rejected',
      'reviewNote': accept ? '' : note.trim(),
      'reviewedBy': reviewerId,
      'reviewedName': reviewerName,
      'reviewedAt': FieldValue.serverTimestamp(),
    };
    await ref.update({...verdict, 'seenBy.$reviewerId': FieldValue.serverTimestamp()});
    // the same verdict on the attempt it was given to, in the student's history
    final attempt = data?['attempt'];
    if (attempt is String && attempt.isNotEmpty) await ref.collection('attempts').doc(attempt).update(verdict).catchError((_) {});
    if (!accept && before != 'approved') return;
    final user = _db.collection('users').doc(uid);
    final solved = List<String>.from((((await user.get()).data()?['solvedIds']) as List?) ?? const []);
    if (accept == solved.contains(key)) return; // already counted, or already not
    await user.set({
      'solvedIds': accept ? FieldValue.arrayUnion([key]) : FieldValue.arrayRemove([key]),
      'solvedCount': FieldValue.increment(accept ? 1 : -1),
    }, SetOptions(merge: true));
  }

  /// What students sent for a teacher's homework: student id -> problem key -> solution.
  static Stream<Map<String, Map<String, Solution>>> solutionsFor(String teacherId) =>
      solutions.where('teachers', arrayContains: teacherId).snapshots().map((q) {
        final out = <String, Map<String, Solution>>{};
        for (final d in q.docs) {
          final s = Solution.fromJson(d.data());
          (out[s.uid] ??= {})[s.key] = s;
        }
        return out;
      });

  /// The teacher opened what [uid] sent on [key]: it's no longer new for them.
  static Future<void> markSeen(String uid, String key, String teacherId) =>
      solutions.doc(solutionId(uid, key)).update({'seenBy.$teacherId': FieldValue.serverTimestamp()});

  static Future<void> setHidden(String id, String uid, bool hidden) =>
      homework.doc(id).update({'hidden.$uid': hidden ? true : FieldValue.delete()});

  /// Opens the student's own copy of the attached Atelier page, creating it
  /// from the teacher's current version the first time. Returns the share id.
  static Future<String> openMaterial(Homework hw, String uid, String studentName) async {
    final m = hw.material!;
    final id = Workspace.shareId(m.docId, uid);
    final existing = await Workspace.shares.doc(id).get();
    if (existing.exists) return id;
    final src = await Workspace.docs.doc(m.docId).get();
    if (!src.exists) throw StateError('Materialul a fost șters de profesor.');
    final d = WsDoc.fromSnap(src);
    await Workspace.shares.doc(id).set({
      'docId': d.id,
      'type': d.type,
      'title': d.title,
      'content': d.content,
      'lang': d.lang,
      'stdin': d.stdin,
      'teacherId': hw.teacherId,
      'teacherName': hw.teacherName,
      'studentId': uid,
      'studentName': studentName,
      'message': 'Temă: ${hw.displayTitle}',
      'sentAt': FieldValue.serverTimestamp(),
      'seenAt': null,
      'version': 1,
    });
    return id;
  }

  /// Students the teacher can pick by name: everyone in their classes plus
  /// anyone they have a conversation with.
  static Future<List<HwStudent>> studentsOf(String teacherId, List<SchoolClass> mine) async {
    final out = <String, String>{};
    for (final c in mine) {
      for (final m in c.members) {
        out[m.id] = m.name;
      }
    }
    try {
      for (final s in await Workspace.studentsOf(teacherId)) {
        out.putIfAbsent(s.id, () => s.name);
      }
    } catch (_) {}
    final list = [for (final e in out.entries) HwStudent(e.key, e.value)];
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  static Future<String> userName(String uid) async {
    try {
      final d = await _db.collection('users').doc(uid).get();
      final n = '${d.data()?['name'] ?? ''}'.trim();
      if (n.isNotEmpty) return n;
    } catch (_) {}
    return 'Elev';
  }

  static Future<String?> roleOf(String uid) async {
    try {
      final d = await _db.collection('users').doc(uid).get();
      return d.data()?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ---- invite links opened while logged out
  static const String _pendingKey = 'pending_class_invite';

  static Future<void> rememberInvite(String code) async {
    try {
      (await SharedPreferences.getInstance()).setString(_pendingKey, code);
    } catch (_) {}
  }

  static Future<void> forgetInvite() async {
    try {
      (await SharedPreferences.getInstance()).remove(_pendingKey);
    } catch (_) {}
  }

  /// Where a student goes right after logging in or signing up: back to the
  /// class they were invited to, if any, otherwise [fallback].
  static Future<String> studentLanding([String fallback = '/materii']) async {
    try {
      final code = (await SharedPreferences.getInstance()).getString(_pendingKey);
      if (code != null && code.isNotEmpty) return '/clasa/$code';
    } catch (_) {}
    return fallback;
  }
}

/// Merges the direct-homework query with the per-class query, re-subscribing
/// to the latter whenever the student's list of classes changes.
class _Merge {
  final Stream<QuerySnapshot<Map<String, dynamic>>> direct;
  final Stream<List<SchoolClass>> classes;
  final Stream<QuerySnapshot<Map<String, dynamic>>> Function(List<String> ids) byClasses;

  _Merge({required this.direct, required this.classes, required this.byClasses});

  late final Stream<List<Homework>> stream = _build();

  Stream<List<Homework>> _build() {
    late final StreamController<List<Homework>> out;
    var directDocs = <Homework>[];
    var classDocs = <Homework>[];
    var gotDirect = false;
    var gotClasses = false;
    StreamSubscription? directSub, classesSub, classSub;
    String? classKey;

    void emit() {
      if (!gotDirect || !gotClasses) return;
      final byId = <String, Homework>{for (final h in classDocs) h.id: h, for (final h in directDocs) h.id: h};
      final list = byId.values.toList()
        ..sort((a, b) {
          // Due soonest first, then the ones without a due date, newest first.
          if (a.dueAt != null && b.dueAt != null) return a.dueAt!.compareTo(b.dueAt!);
          if (a.dueAt != null) return -1;
          if (b.dueAt != null) return 1;
          return Classes._byNewest(a.createdAt, b.createdAt);
        });
      out.add(list);
    }

    out = StreamController<List<Homework>>(
      onListen: () {
        directSub = direct.listen((s) {
          directDocs = s.docs.map(Homework.fromSnap).toList();
          gotDirect = true;
          emit();
        }, onError: out.addError);
        classesSub = classes.listen((list) {
          // arrayContainsAny takes at most 30 values.
          final ids = [for (final c in list) c.id].take(30).toList();
          final key = ids.join(',');
          if (key == classKey) return;
          classKey = key;
          classSub?.cancel();
          if (ids.isEmpty) {
            classDocs = [];
            gotClasses = true;
            emit();
            return;
          }
          classSub = byClasses(ids).listen((s) {
            classDocs = s.docs.map(Homework.fromSnap).toList();
            gotClasses = true;
            emit();
          }, onError: out.addError);
        }, onError: out.addError);
      },
      onCancel: () {
        directSub?.cancel();
        classesSub?.cancel();
        classSub?.cancel();
      },
    );
    return out.stream;
  }
}

/// What a student sent on one problem.
class Solution {
  /// [lastLang] of a maths solution written on a sheet (an ink page).
  static const String sheet = 'ink';

  final String uid;
  final String key;
  final String last;
  final String? lastLang;
  final bool lastPassed;
  final DateTime? lastAt;
  final String? passed; // the last version that passed, if any
  final String? passedLang;
  final DateTime? passedAt;
  final Map<String, DateTime?> seenBy; // teacher id -> when they last opened it
  final Map<String, DateTime?> due; // teacher id -> the latest deadline of their homework with this problem
  // a sheet: checked by a person
  final List<String> photos; // pictures of the solution written on paper
  final String review; // '' | pending | approved | rejected
  final String reviewNote; // why it wasn't accepted
  final String reviewedName;
  final DateTime? reviewedAt;
  final String studentName;
  final HwProblem? exercise;
  const Solution({
    this.uid = '',
    this.key = '',
    required this.last,
    this.lastLang,
    this.lastPassed = false,
    this.lastAt,
    this.passed,
    this.passedLang,
    this.passedAt,
    this.seenBy = const {},
    this.due = const {},
    this.photos = const [],
    this.review = '',
    this.reviewNote = '',
    this.reviewedName = '',
    this.reviewedAt,
    this.studentName = '',
    this.exercise,
  });

  bool get isSheet => lastLang == sheet;
  bool get pending => review == 'pending';
  bool get approved => review == 'approved';
  bool get rejected => review == 'rejected';

  /// Sent since [teacherId] last opened it.
  bool isNewFor(String teacherId) {
    final seen = seenBy[teacherId];
    return lastAt != null && (seen == null || lastAt!.isAfter(seen));
  }

  /// When it was solved (or last tried, if never) came after [teacherId]'s deadline.
  bool lateFor(String teacherId) {
    final d = due[teacherId];
    final at = passedAt ?? lastAt;
    return d != null && at != null && at.isAfter(d);
  }

  static Solution fromJson(Map<String, dynamic> j) {
    DateTime? time(dynamic v) => v is Timestamp ? v.toDate() : null;
    final due = <String, DateTime?>{};
    for (final h in ((j['hw'] as Map?) ?? const {}).values) {
      if (h is! Map) continue;
      final t = '${h['teacher'] ?? ''}';
      final d = time(h['due']);
      // the latest deadline wins; homework without one means it's never late
      if (!due.containsKey(t) || (due[t] != null && (d == null || d.isAfter(due[t]!)))) due[t] = d;
    }
    return Solution(
      uid: '${j['uid'] ?? ''}',
      key: '${j['key'] ?? ''}',
      last: '${j['last'] ?? ''}',
      lastLang: j['lastLang'] as String?,
      lastPassed: j['lastPassed'] == true,
      lastAt: time(j['lastAt']),
      passed: j['passed'] as String?,
      passedLang: j['passedLang'] as String?,
      passedAt: time(j['passedAt']),
      seenBy: {for (final e in ((j['seenBy'] as Map?) ?? const {}).entries) '${e.key}': time(e.value)},
      due: due,
      photos: [for (final u in (j['photos'] as List?) ?? const []) '$u'],
      review: '${j['review'] ?? ''}',
      reviewNote: '${j['reviewNote'] ?? ''}',
      reviewedName: '${j['reviewedName'] ?? ''}',
      reviewedAt: time(j['reviewedAt']),
      studentName: '${j['studentName'] ?? ''}',
      exercise: j['exercise'] is Map ? HwProblem.fromJson(j['exercise'] as Map) : null,
    );
  }
}

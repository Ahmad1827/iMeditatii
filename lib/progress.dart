import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bumped whenever a problem is marked solved on this device, so every list
/// showing the little check marks redraws at once, whichever way the student
/// leaves the problem (back, the breadcrumb, a link).
final ValueNotifier<int> solvedChanged = ValueNotifier(0);

/// Progress keys look like "<materie>_<clasa>_<id>" (see ExerciseDetailScreen).
final RegExp progressKey = RegExp(r'^(.+?)_(\d+)_(.+)$');

/// Every problem the student solved: the ones saved on this device and, when
/// logged in, the ones saved on the account (solved on another device, or
/// before this browser's storage was cleared). The profile counts the same set.
Future<Set<String>> solvedKeys() async {
  final keys = <String>{};
  try {
    final prefs = await SharedPreferences.getInstance();
    // prefs.get(), not getBool(): getBool throws on String values (e.g. 'app_style').
    keys.addAll(prefs.getKeys().where((k) => progressKey.hasMatch(k) && prefs.get(k) == true));
  } catch (_) {}
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      keys.addAll(((doc.data()?['solvedIds'] as List?) ?? const []).map((e) => '$e'));
    } catch (_) {}
  }
  return keys;
}

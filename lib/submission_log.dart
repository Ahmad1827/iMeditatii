import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What a student sent on a problem, kept on this device so "Trimiterile mele"
/// still shows it, with its date, on the next visit: "trimiteri:<progress key>"
/// -> a JSON list, newest first. Text, never a bool, so it never counts as solved.
const String sentPrefix = 'trimiteri:';

/// The most kept for one problem; older ones fall off the end.
const int sentKept = 50;

/// The saved list as it is read back; anything unreadable is an empty list.
List<Map<String, dynamic>> decodeSent(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    return [
      for (final e in jsonDecode(raw) as List)
        if (e is Map && DateTime.tryParse('${e['at']}') != null) Map<String, dynamic>.from(e),
    ];
  } catch (_) {
    return [];
  }
}

/// [all] (newest first, runs on the examples among them) as it is saved: the
/// submissions only, the newest [sentKept].
String encodeSent(List<Map<String, dynamic>> all) =>
    jsonEncode(all.where((s) => s['submit'] == true && s['at'] != null).take(sentKept).toList());

Future<List<Map<String, dynamic>>> loadSent(String key) async {
  try {
    return decodeSent((await SharedPreferences.getInstance()).getString('$sentPrefix$key'));
  } catch (_) {
    return [];
  }
}

Future<void> saveSent(String key, List<Map<String, dynamic>> all) async {
  try {
    await (await SharedPreferences.getInstance()).setString('$sentPrefix$key', encodeSent(all));
  } catch (_) {}
}

/// When it was sent: "azi, 14:05", "ieri, 09:30", then the date, with the
/// year once it is another one.
String sentWhen(Object? at, {DateTime? now}) {
  final d = DateTime.tryParse('$at')?.toLocal();
  if (d == null) return '–';
  final n = now ?? DateTime.now();
  final hour = DateFormat('HH:mm').format(d);
  bool same(DateTime a) => a.year == d.year && a.month == d.month && a.day == d.day;
  if (same(n)) return 'azi, $hour';
  if (same(DateTime(n.year, n.month, n.day - 1))) return 'ieri, $hour';
  return '${DateFormat(d.year == n.year ? 'dd.MM' : 'dd.MM.yyyy').format(d)}, $hour';
}

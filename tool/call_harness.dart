// Both ends of a call in one page, signalling through an in-memory Firestore.
// Build: flutter build web -t tool/call_harness.dart; open with fake media flags.
import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iMeditatii/peer_call.dart';

void log(String s) => print('HARNESS $s'); // ignore: avoid_print

Future<bool> until(bool Function() ok, {int seconds = 20}) async {
  for (var i = 0; i < seconds * 10; i++) {
    if (ok()) return true;
    await Future.delayed(const Duration(milliseconds: 100));
  }
  return false;
}

void main() {
  runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('call harness')))));
  run().catchError((Object e, StackTrace st) => log('FAILED $e\n$st'));
}

Future<void> run() async {
  final db = FakeFirebaseFirestore();
  final got = <String>[];
  PeerCall make(bool teacher, String name) => PeerCall(
        roomId: 'room1',
        isOfferer: teacher,
        myName: name,
        db: db,
        onMessage: (m) => got.add('$name<-${m['t']}'),
        onChannelOpen: () => log('$name channel open'),
      );

  // a stale offer from an earlier lesson is already there
  await db.collection('chats').doc('room1').collection('call').doc('signal').set({
    'offer': {'id': 'old', 'sdp': 'v=0'},
  });

  final s1 = make(false, 'student');
  await s1.start();
  log('student alone: ${s1.link}');
  final t = make(true, 'teacher');
  await t.start();
  log('mic ${t.hasMic} cam ${t.hasCamera}');
  log('connected: ${await until(() => t.link == CallLink.connected && s1.link == CallLink.connected)}');
  await until(() => t.remoteName != null && s1.remoteName != null);
  log('names: ${t.remoteName} / ${s1.remoteName}');

  s1.send({'t': 's', 'id': 'a', 'c': 1, 'w': 2, 'p': [0.1, 0.1]});
  t.send({'t': 'clr'});
  await until(() => got.length >= 2, seconds: 5);
  log('messages: $got');

  s1.toggleMic();
  await until(() => t.remoteMicOff, seconds: 5);
  log('teacher sees student muted: ${t.remoteMicOff}');

  await Future.delayed(const Duration(seconds: 5));
  log('signal: ${t.signal} / ${s1.signal}');

  final share = await t.toggleShare();
  log('share: ${t.sharing} msg=$share');
  log('student sees share: ${await until(() => s1.remoteSharing, seconds: 5)}');

  // the student reloads the page
  await s1.leave();
  log('teacher after student left: ${await until(() => t.link == CallLink.waiting, seconds: 10)} ${t.link}');
  final s2 = make(false, 'student2');
  await s2.start();
  log('rejoined: ${await until(() => t.link == CallLink.connected && s2.link == CallLink.connected)}');
  log('student2 sees share kept: ${await until(() => s2.remoteSharing, seconds: 5)}');

  // the teacher reloads the page
  await t.leave();
  log('student after teacher left: ${await until(() => s2.link == CallLink.waiting, seconds: 10)} ${s2.link}');
  final t2 = make(true, 'teacher2');
  await t2.start();
  log('teacher rejoined: ${await until(() => t2.link == CallLink.connected && s2.link == CallLink.connected)}');
  log('DONE');
}

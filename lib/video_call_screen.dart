import 'package:flutter/material.dart';
import 'dart:ui' as ui; // pentru registrarea iframe
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomId;
  const VideoCallScreen({super.key, required this.roomId});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  @override
  void initState() {
    super.initState();

    final callUrl = "https://meet.jit.si/${widget.roomId}";

    // Înregistrează un viewType pentru iframe
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'jitsi-iframe',
          (int viewId) {
        final iframe = html.IFrameElement()
          ..src = callUrl
          ..style.border = 'none'
          ..allow = "camera; microphone; fullscreen; display-capture";
        return iframe;
      },
    );
  }
  @override
  void dispose() {
    // când utilizatorul părăsește ecranul apelului
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.roomId)
        .update({
      'activeCall': FieldValue.delete(),
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text("Apel Video"),
      ),
      body: const HtmlElementView(
        viewType: 'jitsi-iframe',
      ),
    );
  }
}

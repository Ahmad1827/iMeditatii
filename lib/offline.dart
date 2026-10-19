import 'package:flutter/material.dart';

import 'offline_stub.dart' if (dart.library.js_interop) 'offline_web.dart' as impl;
import 'ui_components.dart' show Pb;

/// The browser has no network. What was opened before still works: the app
/// and its files come from web/sw.js, Firestore data from its own cache, and
/// what is sent meanwhile goes out when the network is back.
class Offline {
  static final ValueNotifier<bool> notifier = () {
    final n = ValueNotifier<bool>(!impl.online());
    impl.listen((online) => n.value = !online);
    return n;
  }();
}

/// A small note at the top of every page while offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Offline.notifier,
      builder: (context, offline, _) => Positioned(
        top: 68 + MediaQuery.of(context).padding.top,
        left: 12,
        right: 12,
        child: IgnorePointer(
          child: AnimatedSlide(
            offset: offline ? Offset.zero : const Offset(0, -0.4),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: offline ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Pb.text,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off, size: 16, color: Pb.surface),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Ești offline. Ce ai deschis deja merge în continuare; ce trimiți pleacă când revine netul.',
                            style: TextStyle(fontSize: 13, color: Pb.surface, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_colors.dart';
import 'app_link_stub.dart' if (dart.library.js_interop) 'app_link_web.dart' as impl;
import 'design_system.dart' show Pb;
import 'theme_manager.dart';

/// The app's top navigator: the menu opens above everything, also for what
/// lives outside the pages (the homework dock).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> launchInNewTab(String to) => launchUrl(AppLink.uri(to), webOnlyWindowName: '_blank');

/// What goes to a page can also be opened in a new tab, like a link: a right
/// click on [child] offers it, and the click itself stays [child]'s own.
/// [to] is the address inside the app, '/resurse/12'.
class AppLink extends StatelessWidget {
  final String? to;
  final Widget child;

  const AppLink({super.key, required this.to, required this.child});

  // A link inside a link (a button on a card): the innermost one answers. It
  // hears the press first, the one around it sees the press is taken.
  static int? _taken;

  static Uri uri(String to) => Uri.parse('${Uri.base.origin}$to');

  static Future<void> _show(String to, Offset at) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    final retro = ThemeManager.styleNotifier.value == AppStyleMode.retro;
    final ink = retro ? AppColors.ink : Pb.text;
    PopupMenuItem<String> item(String value, IconData icon, String label) => PopupMenuItem<String>(
          value: value,
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: ink),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: 14, color: ink)),
            ],
          ),
        );
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx, at.dy),
      color: retro ? AppColors.cardBg : Pb.surface,
      elevation: 8,
      shape: retro
          ? RoundedRectangleBorder(side: BorderSide(color: AppColors.border, width: 2))
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Pb.border)),
      items: [
        item('tab', Icons.open_in_new, 'Deschide într-o filă nouă'),
        item('copy', Icons.link, 'Copiază linkul'),
      ],
    );
    if (picked == 'tab') {
      await launchInNewTab(to);
    } else if (picked == 'copy') {
      await Clipboard.setData(ClipboardData(text: uri(to).toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final to = this.to;
    if (!kIsWeb || to == null) return child;
    int? mine;
    return Listener(
      onPointerDown: (e) {
        mine = null;
        if (e.kind != PointerDeviceKind.mouse || e.buttons & kSecondaryMouseButton == 0 || _taken == e.pointer) return;
        _taken = e.pointer;
        mine = e.pointer;
        impl.keepBrowserMenuAway();
      },
      onPointerUp: (e) {
        if (mine == e.pointer) _show(to, e.position);
        mine = null;
      },
      child: child,
    );
  }
}

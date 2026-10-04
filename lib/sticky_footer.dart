import 'package:flutter/material.dart';

/// Scroll view with a footer that sits at the very bottom of the screen when
/// the content is short, and right after the content when it's long.
class StickyFooterScroll extends StatelessWidget {
  final ScrollController controller;
  final Widget body;
  final Widget footer;
  final double gap;

  const StickyFooterScroll({
    super.key,
    required this.controller,
    required this.body,
    required this.footer,
    this.gap = 56,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, viewport) => Scrollbar(
        controller: controller,
        child: SingleChildScrollView(
          controller: controller,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: viewport.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                body,
                Padding(padding: EdgeInsets.only(top: gap), child: footer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
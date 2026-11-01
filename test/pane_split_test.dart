// The divider between two panes: it moves with the mouse, stops at the minimums,
// and a double click brings it back.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/pane_split.dart';

void main() {
  const a = Key('a');
  const b = Key('b');

  Future<void> pump(WidgetTester t, Axis axis, {double start = 0.5, Size size = const Size(1000, 1000), VoidCallback? onEnd}) async {
    var ratio = start;
    await t.pumpWidget(Center(
      child: SizedBox.fromSize(
        size: size,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (_, set) => PaneSplit(
              axis: axis,
              ratio: ratio,
              defaultRatio: 0.5,
              minFirst: 200,
              minSecond: 300,
              onChanged: (r) => set(() => ratio = r),
              onChangeEnd: onEnd,
              first: const SizedBox.expand(key: a),
              second: const SizedBox.expand(key: b),
            ),
          ),
        ),
      ),
    ));
    await t.pump();
  }

  // the divider is the gap between the two panes
  Offset gap(WidgetTester t) => (t.getBottomRight(find.byKey(a)) + t.getTopLeft(find.byKey(b))) / 2;

  testWidgets('dragging moves the divider and says when it ended', (t) async {
    t.view.physicalSize = const Size(1400, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    var ended = 0;
    await pump(t, Axis.horizontal, onEnd: () => ended++);
    final w = t.getSize(find.byKey(a)).width;
    await t.dragFrom(Offset(gap(t).dx, t.getCenter(find.byKey(a)).dy), const Offset(120, 0), touchSlopX: 0);
    await t.pump(const Duration(seconds: 1));
    expect(t.getSize(find.byKey(a)).width, closeTo(w + 120, 1));
    expect(t.getSize(find.byKey(a)).width + t.getSize(find.byKey(b)).width + 14, closeTo(1000, 0.01));
    expect(ended, 1);
  });

  testWidgets('one over the other, it moves up and down', (t) async {
    t.view.physicalSize = const Size(1400, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await pump(t, Axis.vertical);
    final h = t.getSize(find.byKey(a)).height;
    await t.dragFrom(Offset(t.getCenter(find.byKey(a)).dx, gap(t).dy), const Offset(0, -100), touchSlopY: 0);
    await t.pump(const Duration(seconds: 1));
    expect(t.getSize(find.byKey(a)).height, closeTo(h - 100, 1));
  });

  testWidgets('neither pane goes under its minimum', (t) async {
    t.view.physicalSize = const Size(1400, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await pump(t, Axis.horizontal);
    await t.dragFrom(Offset(gap(t).dx, 500), const Offset(-900, 0), touchSlopX: 0);
    await t.pump(const Duration(seconds: 1));
    expect(t.getSize(find.byKey(a)).width, 200);
    await t.dragFrom(Offset(gap(t).dx, 500), const Offset(1500, 0), touchSlopX: 0);
    await t.pump(const Duration(seconds: 1));
    expect(t.getSize(find.byKey(b)).width, 300);
  });

  testWidgets('a saved size that no longer fits still leaves both panes on screen', (t) async {
    t.view.physicalSize = const Size(1400, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await pump(t, Axis.horizontal, start: 0.95, size: const Size(420, 500));
    expect(t.takeException(), isNull);
    expect(t.getSize(find.byKey(a)).width, closeTo(203, 0.01));
    expect(t.getSize(find.byKey(b)).width, closeTo(203, 0.01));
  });

  testWidgets('a double click puts it back', (t) async {
    t.view.physicalSize = const Size(1400, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await pump(t, Axis.horizontal, start: 0.3);
    final at = Offset(gap(t).dx, 500);
    await t.tapAt(at);
    await t.pump(const Duration(milliseconds: 50));
    await t.tapAt(at);
    await t.pumpAndSettle();
    expect(t.getSize(find.byKey(a)).width, closeTo((1000 - 14) / 2, 0.01));
  });
}

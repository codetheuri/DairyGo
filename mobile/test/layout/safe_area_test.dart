// Checks that nothing the user taps or types into sits under the system bars,
// a camera cutout, or the curved edge of the screen, on real device shapes.
//
// Since Android 15 apps draw edge to edge: the status bar, the camera cutout
// and the gesture bar are drawn over the app, and each screen must keep its
// controls clear of them. Each screen is scrolled to the end first, because
// what matters is whether the last button can be reached.
//
//   flutter test test/layout/safe_area_test.dart
//
// Screenshots with the system areas shaded:
//
//   flutter test test/layout/safe_area_test.dart --update-goldens --dart-define=SCREENSHOTS=true

import 'package:dairy_sacco_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _screenshots = bool.fromEnvironment('SCREENSHOTS');

/// A device: logical size, the areas the system draws over, and how far from
/// the left and right edges the glass curves (0 for flat screens).
class _Device {
  final Size size;
  final EdgeInsets system;
  final double curvedEdge;

  const _Device(this.size, this.system, {this.curvedEdge = 0});
}

const _devices = <String, _Device>{
  // Punch-hole camera and gesture navigation (e.g. Pixel, Galaxy A series).
  'notch-phone': _Device(Size(412, 915), EdgeInsets.fromLTRB(0, 48, 0, 24)),
  // The same phone turned sideways: the camera cutout is on the left.
  'notch-landscape': _Device(
    Size(915, 412),
    EdgeInsets.fromLTRB(48, 24, 0, 24),
  ),
  // Curved "edge" screen: the outer 8 dp of each side bends away.
  'curved-edge': _Device(
    Size(384, 854),
    EdgeInsets.fromLTRB(0, 36, 0, 24),
    curvedEdge: 8,
  ),
  // Small phone with the older 3-button navigation bar.
  'small-3-button': _Device(Size(360, 640), EdgeInsets.fromLTRB(0, 24, 0, 48)),
  // Unfolded foldable (e.g. Galaxy Z Fold).
  'foldable-open': _Device(Size(673, 841), EdgeInsets.fromLTRB(0, 24, 0, 24)),
  // Large tablet in landscape.
  'tablet-large': _Device(Size(1366, 1024), EdgeInsets.fromLTRB(0, 24, 0, 20)),
};

/// Controls the user taps or types into.
bool _isControl(Widget w) =>
    w is ButtonStyleButton ||
    w is FloatingActionButton ||
    w is IconButton ||
    w is TextField ||
    w is SegmentedButton ||
    w is ListTile ||
    w is Checkbox ||
    w is Switch ||
    w is DropdownButton;

String _describe(Widget w) {
  String? text;
  if (w is ButtonStyleButton && w.child is Text) text = (w.child as Text).data;
  if (w is FloatingActionButton) text = 'floating button';
  if (w is IconButton) text = w.tooltip ?? 'icon button';
  if (w is TextField) text = w.decoration?.labelText ?? w.decoration?.hintText;
  if (w is ListTile && w.title is Text) text = (w.title as Text).data;
  return '${w.runtimeType}${text == null ? '' : ' "$text"'}';
}

/// Scrolls every vertical list or page to its end.
Future<void> _scrollToEnd(WidgetTester tester) async {
  for (final state in tester.stateList<ScrollableState>(
    find.byType(Scrollable),
  )) {
    final position = state.position;
    if (position.axis == Axis.vertical && position.maxScrollExtent > 0) {
      position.jumpTo(position.maxScrollExtent);
    }
  }
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Controls the user could tap, overlapping an unsafe area, and why.
List<String> _unsafeControls(WidgetTester tester, _Device device) {
  final screen = Offset.zero & device.size;
  final s = device.system;
  final areas = <String, Rect>{
    if (s.bottom > 0)
      'gesture/navigation bar': Rect.fromLTRB(
        0,
        screen.bottom - s.bottom,
        screen.right,
        screen.bottom,
      ),
    if (s.left > 0) 'camera cutout': Rect.fromLTRB(0, 0, s.left, screen.bottom),
    if (s.right > 0)
      'camera cutout': Rect.fromLTRB(
        screen.right - s.right,
        0,
        screen.right,
        screen.bottom,
      ),
    if (s.top > 0) 'status bar': Rect.fromLTRB(0, 0, screen.right, s.top),
  };
  final problems = <String>[];
  // Only controls the user can actually hit (not hidden under an app bar).
  final controls = find.byWidgetPredicate(_isControl).hitTestable();
  for (final element in controls.evaluate()) {
    final box = element.renderObject as RenderBox?;
    if (box == null || !box.hasSize) continue;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (!rect.overlaps(screen)) continue;
    for (final area in areas.entries) {
      final overlap = rect.intersect(area.value);
      if (overlap.width > 1 && overlap.height > 1) {
        problems.add(
          '${_describe(element.widget)} under the ${area.key} '
          '(${overlap.height.toStringAsFixed(0)} dp)',
        );
      }
    }
    // Buttons and fields on the bend of a curved screen are hard to tap and
    // read. Icon buttons are judged by their icon: the 48 dp tap area of a
    // back arrow may reach the edge, the 24 dp icon must not. List rows and
    // full-width fields may run edge to edge.
    if (device.curvedEdge > 0 && element.widget is! ListTile) {
      final isIcon =
          element.widget is IconButton ||
          element.widget.runtimeType.toString().startsWith('_IconButton');
      final visible = isIcon ? rect.deflate(12) : rect;
      final near =
          visible.left < device.curvedEdge ||
          visible.right > screen.right - device.curvedEdge;
      if (near && rect.width < screen.width - 2 * device.curvedEdge) {
        problems.add('${_describe(element.widget)} on the curved edge');
      }
    }
  }
  return problems;
}

void main() {
  setUpAll(loadFonts);

  for (final role in ['collector', 'admin', 'board']) {
    for (final route in routesByRole[role]!) {
      testWidgets('$role $route keeps controls clear of system areas', (
        tester,
      ) async {
        final problems = <String>[];

        for (final entry in _devices.entries) {
          final device = entry.value;
          const dpr = 3.0;
          tester.view.devicePixelRatio = dpr;
          tester.view.physicalSize = device.size * dpr;
          final insets = FakeViewPadding(
            left: device.system.left * dpr,
            top: device.system.top * dpr,
            right: device.system.right * dpr,
            bottom: device.system.bottom * dpr,
          );
          tester.view.padding = insets;
          tester.view.viewPadding = insets;

          final app = await AppUnderTest.open(tester, role, route);
          try {
            await _scrollToEnd(tester);
            for (final p in _unsafeControls(tester, device).toSet()) {
              problems.add('${entry.key}: $p');
            }
            for (final e in app.errors.toSet()) {
              problems.add('${entry.key}: $e');
            }
            if (_screenshots && role != 'board') {
              await expectLater(
                find.byType(DairySaccoApp),
                matchesGoldenFile(
                  'screenshots/safe_$role${route.replaceAll('/', '_')}_${entry.key}.png',
                ),
              );
            }
          } finally {
            await app.close();
          }
        }

        tester.view.reset();
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  }
}

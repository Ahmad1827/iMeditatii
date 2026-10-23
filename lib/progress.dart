import 'package:flutter/foundation.dart';

/// Bumped whenever a problem is marked solved on this device, so every list
/// showing the little check marks redraws at once, whichever way the student
/// leaves the problem (back, the breadcrumb, a link).
final ValueNotifier<int> solvedChanged = ValueNotifier(0);

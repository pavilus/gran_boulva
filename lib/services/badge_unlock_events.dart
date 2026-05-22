import 'dart:async';

import '../models/models.dart';

class BadgeUnlockEvents {
  const BadgeUnlockEvents._();

  static final _controller = StreamController<BadgeEventResult>.broadcast();

  static Stream<BadgeEventResult> get stream => _controller.stream;

  static void show(BadgeEventResult result) {
    if (!_controller.isClosed) _controller.add(result);
  }
}

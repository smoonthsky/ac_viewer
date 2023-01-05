import 'dart:async';

import 'package:flutter/foundation.dart';

///The Debouncer class is a utility class that can be used to debounce a function call.
///
///It works by taking a VoidCallback action, which is the function that you want to debounce, and a Duration delay, which is the amount of time that should elapse between calls to the action.
///
///When the call method is called, it first cancels any existing timer that may be running.
///
///It then starts a new timer that will run the action after the specified delay has elapsed.
///
///This can be useful in situations where you want to limit the rate at which an action is called, for example, to prevent a search function from being called too frequently or to prevent a user interface from updating too frequently.
class Debouncer {
  final Duration delay;

  Timer? _timer;

  Debouncer({required this.delay});

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
}

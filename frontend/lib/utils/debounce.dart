import 'dart:async';
import 'package:flutter/material.dart';

/// Debouncer to prevent rapid repeated function calls
/// Useful for search inputs, button presses, etc.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  /// Call the function after delay, cancelling previous calls
  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancel any pending calls
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose of the debouncer
  void dispose() {
    _timer?.cancel();
  }
}

/// Throttler to limit function call frequency
/// First call executes immediately, subsequent calls are ignored until duration passes
class Throttler {
  final Duration duration;
  DateTime? _lastCallTime;

  Throttler({required this.duration});

  /// Call the function only if enough time has passed since last call
  void call(VoidCallback action) {
    final now = DateTime.now();

    if (_lastCallTime == null || now.difference(_lastCallTime!) >= duration) {
      _lastCallTime = now;
      action();
    }
  }

  /// Reset the throttler
  void reset() {
    _lastCallTime = null;
  }
}

/// Rate limiter with cooldown period
/// Prevents too many calls within a time window
class RateLimiter {
  final int maxCalls;
  final Duration window;
  final List<DateTime> _callTimes = [];

  RateLimiter({
    required this.maxCalls,
    required this.window,
  });

  /// Check if call is allowed within rate limit
  bool canCall() {
    final now = DateTime.now();

    // Remove old calls outside the window
    _callTimes.removeWhere((time) => now.difference(time) > window);

    return _callTimes.length < maxCalls;
  }

  /// Execute action if within rate limit
  bool call(VoidCallback action) {
    if (canCall()) {
      _callTimes.add(DateTime.now());
      action();
      return true;
    }
    return false;
  }

  /// Get remaining calls in current window
  int remainingCalls() {
    final now = DateTime.now();
    _callTimes.removeWhere((time) => now.difference(time) > window);
    return maxCalls - _callTimes.length;
  }

  /// Get time until next call is allowed
  Duration? timeUntilNextCall() {
    if (canCall()) return Duration.zero;

    final now = DateTime.now();
    _callTimes.removeWhere((time) => now.difference(time) > window);

    if (_callTimes.isEmpty) return Duration.zero;

    final oldest = _callTimes.first;
    final elapsed = now.difference(oldest);
    return window - elapsed;
  }

  /// Reset the rate limiter
  void reset() {
    _callTimes.clear();
  }
}

/// Mixin for widgets that need debouncing
mixin DebounceMixin<T extends StatefulWidget> on State<T> {
  final Map<String, Debouncer> _debouncers = {};

  /// Create or get a debouncer with a key
  void debounce(
    String key,
    VoidCallback action, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    _debouncers[key] ??= Debouncer(delay: delay);
    _debouncers[key]!.call(action);
  }

  @override
  void dispose() {
    for (var debouncer in _debouncers.values) {
      debouncer.dispose();
    }
    super.dispose();
  }
}

/// Extension on VoidCallback for easy debouncing
extension DebouncedCallback on VoidCallback {
  VoidCallback debounced({
    Duration delay = const Duration(milliseconds: 500),
  }) {
    final debouncer = Debouncer(delay: delay);
    return () => debouncer.call(this);
  }

  VoidCallback throttled({
    Duration duration = const Duration(milliseconds: 500),
  }) {
    final throttler = Throttler(duration: duration);
    return () => throttler.call(this);
  }
}

/// Button that prevents rapid taps
class DebouncedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Duration debounceDelay;
  final ButtonStyle? style;

  const DebouncedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.debounceDelay = const Duration(milliseconds: 500),
    this.style,
  });

  @override
  State<DebouncedButton> createState() => _DebouncedButtonState();
}

class _DebouncedButtonState extends State<DebouncedButton> {
  late final Debouncer _debouncer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(delay: widget.debounceDelay);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _handlePress() {
    if (_isProcessing || widget.onPressed == null) return;

    setState(() => _isProcessing = true);

    _debouncer.call(() {
      widget.onPressed!();
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed:
          widget.onPressed != null && !_isProcessing ? _handlePress : null,
      style: widget.style,
      child: widget.child,
    );
  }
}

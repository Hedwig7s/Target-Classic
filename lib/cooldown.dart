import 'package:meta/meta.dart';

class Cooldown {
  final int maxCount;
  final Duration resetTime;
  @protected
  int _count = 0;
  @protected
  DateTime _lastReset = DateTime.fromMillisecondsSinceEpoch(0);
  int get count => _count;
  DateTime get lastReset => _lastReset;

  Cooldown({required this.maxCount, required this.resetTime});
  bool canUse() {
    _count++;
    if (DateTime.now().difference(_lastReset) > resetTime) {
      _count = 1;
      _lastReset = DateTime.now();
      return true;
    }
    return _count <= maxCount;
  }

  void reset() {
    _count = 0;
    _lastReset = DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  String toString() {
    return 'Cooldown(maxCount: $maxCount, resetTime: $resetTime, count: $_count, lastCounted: $_lastReset)';
  }
}

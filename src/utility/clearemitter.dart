import 'package:events_emitter/events_emitter.dart';

void clearEmitter(EventEmitter emitter) {
  for (var listener in emitter.listeners) {
    emitter.removeEventListener(listener);
  }
}
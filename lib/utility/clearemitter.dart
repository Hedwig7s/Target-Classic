import 'package:events_emitter/events_emitter.dart';

void clearEmitter(EventEmitter emitter) {
  List<EventListener> listeners = emitter.listeners.toList();
  for (var listener in listeners) {
    emitter.removeEventListener(listener);
  }
}

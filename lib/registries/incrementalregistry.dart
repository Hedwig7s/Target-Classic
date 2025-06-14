import 'package:events_emitter/events_emitter.dart';
import 'package:meta/meta.dart';

abstract interface class IRRegisterable {
  Map<IncrementalRegistry, int> get ids;
  EventEmitter get emitter;
}

class IncrementalRegistry<V extends IRRegisterable> {
  @protected
  final Map<int, V> registry = {};
  final EventEmitter emitter = EventEmitter();
  @protected
  final Map<V, EventListener> listeners = {};
  @protected
  int _totalRegistered = 0;

  int get length {
    return registry.length;
  }

  int get totalRegistered => _totalRegistered;

  void register(V item) {
    if (item.ids.containsKey(this)) {
      throw Exception("Item already registered in this registry");
    }
    int id = _totalRegistered++;
    item.ids[this] = id;
    registry[id] = item;
    listeners[item] = item.emitter.on('destroyed', (args) {
      unregister(item);
    });
    emitter.emit('register', item);
  }

  V? get(int id) {
    return registry[id];
  }

  bool contains(int id) {
    return registry.containsKey(id);
  }

  bool containsItem(V item) {
    return item.ids.containsKey(this);
  }

  void unregister(V item) {
    if (!this.containsItem(item)) {
      throw Exception("Item not registered in this registry");
    }
    int id = item.ids[this]!;
    registry.remove(id);
    item.ids.remove(this);
    listeners[item]?.cancel();
    listeners.remove(item);
    emitter.emit('unregister', item);
  }

  void unregisterById(int id) {
    V? item = registry.remove(id);
    if (item == null) return;
    unregister(item);
  }

  List<V> getAll() {
    return registry.values.toList();
  }
}

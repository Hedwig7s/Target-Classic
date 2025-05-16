import 'package:events_emitter/events_emitter.dart';

abstract interface class IRRegisterable {
  Map<IncrementalRegistry, int> get ids;
}

class IncrementalRegistry<V extends IRRegisterable> {
  final Map<int, V> _registry = {};
  final EventEmitter emitter = EventEmitter();
  int _totalRegistered = 0;

  int get totalRegistered => _totalRegistered;

  void register(V item) {
    if (item.ids.containsKey(this)) {
      throw Exception("Item already registered in this registry");
    }
    int id = _totalRegistered++;
    item.ids[this] = id;
    _registry[id] = item;
    emitter.emit('register', item);
  }

  V? get(int id) {
    return _registry[id];
  }

  bool contains(int id) {
    return _registry.containsKey(id);
  }

  bool containsItem(V item) {
    return item.ids.containsKey(this);
  }

  void unregister(V item) {
    if (!this.containsItem(item)) {
      throw Exception("Item not registered in this registry");
    }
    int id = item.ids[this]!;
    _registry.remove(id);
    item.ids.remove(this);
    emitter.emit('unregister', item);
  }

  void unregisterById(int id) {
    V? item = _registry.remove(id);
    if (item == null) return;
    item.ids.remove(this);
    emitter.emit('unregister', item);
  }

  List<V> getAll() {
    return _registry.values.toList();
  }
}

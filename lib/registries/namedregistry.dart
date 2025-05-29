import 'package:events_emitter/events_emitter.dart';
import 'package:meta/meta.dart';

abstract class Nameable<K> {
  K get name;
  EventEmitter? get emitter;
}

class NamedRegistry<K, V extends Nameable<K>> {
  @protected
  final Map<K, V> registry = {};
  final EventEmitter emitter = EventEmitter();
  @protected
  final Map<K, EventListener> listeners = {};

  void register(V item) {
    if (registry.containsKey(item.name) && registry[item.name] != item) {
      throw ArgumentError('Item with name ${item.name} already exists');
    }
    registry[item.name] = item;
    if (item.emitter != null) {
      listeners[item.name] = item.emitter!.on('destroyed', (args) {
        unregister(item);
      });
    }
    emitter.emit('register', item);
  }

  void unregister(V item) {
    if (registry.containsKey(item.name) && registry[item.name] == item) {
      unregisterByName(item.name);
    } else if (registry.containsKey(item.name) && registry[item.name] != item) {
      throw ArgumentError(
        'Item with name ${item.name} exists but is not the same instance',
      );
    }
    // Do nothing if the item is not registered
  }

  void unregisterByName(K name) {
    if (registry.containsKey(name)) {
      registry.remove(name);
      listeners[name]?.cancel();
      listeners.remove(name);
      emitter.emit('unregister', registry[name]);
    }
  }

  V? get(K name) {
    return registry[name];
  }

  bool contains(K name) {
    return registry.containsKey(name);
  }

  List<V> getAll() {
    return registry.values.toList();
  }
}

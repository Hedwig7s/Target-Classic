import 'package:meta/meta.dart';

abstract class Nameable<K> {
  K get name;
}

class NamedRegistry<K, V extends Nameable<K>> {
  @protected
  final Map<K, V> registry = {};

  void register(V item) {
    if (registry.containsKey(item.name) && registry[item.name] != item) {
      throw ArgumentError('Item with name ${item.name} already exists');
    }
    registry[item.name] = item;
  }

  void unregister(V item) {
    if (registry.containsKey(item.name) && registry[item.name] == item) {
      registry.remove(item.name);
    } else if (registry.containsKey(item.name) && registry[item.name] != item) {
      throw ArgumentError('Item with name ${item.name} already exists');
    }
    // Do nothing if the item is not registered
  }

  void unregisterByName(K name) {
    if (registry.containsKey(name)) {
      registry.remove(name);
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

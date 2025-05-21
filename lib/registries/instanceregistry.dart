import 'package:events_emitter/events_emitter.dart';

class InstanceRegistry {
  final Map<String, dynamic> _instances = {};
  final EventEmitter emitter = EventEmitter();

  T getInstance<T>(String name) {
    T? instance = tryGetInstance<T>(name);
    if (instance == null) {
      throw Exception('Service $name not found');
    }
    return instance;
  }

  T? tryGetInstance<T>(String name) {
    if (!_instances.containsKey(name)) return null;
    if (_instances[name] is! T) {
      throw Exception('Service $name is not of type ${T.toString()}');
    }
    return _instances[name];
  }

  void registerInstance<T>(String name, T instance) {
    if (_instances.containsKey(name)) {
      throw Exception('Service $name already registered');
    }
    _instances[name] = instance;
    emitter.emit('register', (name: name, instance: instance));
  }

  void unregisterInstance(String name) {
    if (!_instances.containsKey(name)) {
      throw Exception('Service $name not found');
    }
    var instance = _instances.remove(name);
    emitter.emit('unregister', (name: name, instance: instance));
  }

  void registerInstances(Map<String, dynamic> instances) {
    for (var entry in instances.entries) {
      registerInstance(entry.key, entry.value);
    }
  }
}

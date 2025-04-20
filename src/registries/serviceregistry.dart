class ServiceRegistry {
  final Map<String, dynamic> _services = {};

  T getService<T>(String name) {
    T? service = tryGetService<T>(name);
    if (service == null) {
      throw Exception('Service $name not found');
    }
    return service;
  }

  T? tryGetService<T>(String name) {
    if (!_services.containsKey(name)) return null;
    if (_services[name] is! T) {
      throw Exception('Service $name is not of type ${T.toString()}');
    }
    return _services[name];
  }

  void registerService<T>(String name, T service) {
    if (_services.containsKey(name)) {
      throw Exception('Service $name already registered');
    }
    _services[name] = service;
  }

  void unregisterService(String name) {
    if (!_services.containsKey(name)) {
      throw Exception('Service $name not found');
    }
    _services.remove(name);
  }

  void registerServices(Map<String, dynamic> services) {
    for (var entry in services.entries) {
      registerService(entry.key, entry.value);
    }
  }
}

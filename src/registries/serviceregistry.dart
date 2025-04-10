import '../networking/server.dart';
import '../player.dart';
import '../world.dart';
import '../worldformats/hworld.dart';
import 'namedregistry.dart';
import 'worldregistry.dart';

class ServiceRegistry {
  final Map<String, dynamic> _services = {};

  T getService<T>(String name) {
    if (_services.containsKey(name)) {
      if (_services[name] is! T) {
        throw Exception('Service $name is not of type ${T.toString()}');
      }
      return _services[name];
    } else {
      throw Exception('Service $name not found');
    }
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

Future<ServiceRegistry> getServerServiceRegistry() async {
  ServiceRegistry serviceRegistry = ServiceRegistry();

  NamedRegistry playerRegistry = NamedRegistry<String, Player>();
  serviceRegistry.registerService("playerregistry", playerRegistry);

  NamedRegistryWithDefault worldRegistry =
      NamedRegistryWithDefault<String, World>();
  World defaultWorld = await World.fromFile(
    "./worlds/world.hworld",
    HWorldFormat(),
  );
  worldRegistry.setDefaultItem(defaultWorld);
  serviceRegistry.registerService("worldregistry", worldRegistry);

  Server server = new Server(
    "0.0.0.0",
    25564,
    serviceRegistry: serviceRegistry,
  );
  serviceRegistry.registerService("server", server);
  return serviceRegistry;
}

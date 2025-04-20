import 'dart:io';

import '../datatypes.dart';
import '../networking/server.dart';
import '../player.dart';
import '../world.dart';
import '../worldformats/hworld.dart';
import 'namedregistry.dart';
import 'namedregistrywithdefault.dart';
import 'serviceregistry.dart';

typedef WorldRegistry = NamedRegistryWithDefault<String, World>;
typedef PlayerRegistry = NamedRegistry<String, Player>;

Future<ServiceRegistry> getServerServiceRegistry() async {
  ServiceRegistry serviceRegistry = ServiceRegistry();

  PlayerRegistry playerRegistry = PlayerRegistry();
  serviceRegistry.registerService("playerregistry", playerRegistry);

  WorldRegistry worldRegistry = WorldRegistry();
  World defaultWorld;
  try {
    defaultWorld = await World.fromFile(
      "./worlds/world.hworld",
      HWorldFormat(),
    );
  } catch (e, stackTrace) {
    if (e is FileSystemException) {
      print("File not found, creating default world");
    } else {
      Error.throwWithStackTrace(
        Exception("Failed to load world: $e"),
        stackTrace,
      );
    }
    defaultWorld = World.superflat("world", Vector3I(128, 128, 128));
  }
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

import 'dart:io';

import 'package:logging/logging.dart';

import '../config/serverconfig.dart';
import '../constants.dart';
import 'package:path/path.dart' as p;

import '../datatypes.dart';
import '../networking/server.dart';
import '../player.dart';
import '../world.dart';
import '../worldformats/hworld.dart';
import 'namedregistry.dart';
import 'worldregistry.dart';
import 'instanceregistry.dart';

typedef PlayerRegistry = NamedRegistry<String, Player>;

Future<InstanceRegistry> getServerInstanceRegistry() async {
  final InstanceRegistry instanceRegistry = InstanceRegistry();

  late final ServerConfig serverConfig;
  try {
    serverConfig = await ServerConfig.loadFromFile();
  } catch (e) {
    Logger.root.warning("Failed to load config: $e");
    serverConfig = ServerConfig();
  }
  serverConfig.saveToFile();
  instanceRegistry.registerInstance("serverconfig", serverConfig);

  final PlayerRegistry playerRegistry = PlayerRegistry();
  instanceRegistry.registerInstance("playerregistry", playerRegistry);

  final WorldRegistry worldRegistry = WorldRegistry();
  late final World defaultWorld;
  try {
    defaultWorld = await World.fromFile(
      p.join(WORLD_FOLDER, "world.hworld"),
      HWorldFormat(),
    );
  } catch (e, stackTrace) {
    if (e is FileSystemException) {
      Logger.root.warning("File not found, creating default world");
    } else {
      Error.throwWithStackTrace(
        Exception("Failed to load world: $e"),
        stackTrace,
      );
    }
    defaultWorld = World.superflat("world", Vector3I(128, 128, 128));
  }
  worldRegistry.setDefaultWorld(defaultWorld);
  instanceRegistry.registerInstance("worldregistry", worldRegistry);

  final Server server = new Server(
    serverConfig.host,
    serverConfig.port,
    instanceRegistry: instanceRegistry,
  );
  instanceRegistry.registerInstance("server", server);
  return instanceRegistry;
}

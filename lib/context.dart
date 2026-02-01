import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:target_classic/chat/chatroom.dart';

import 'package:target_classic/config/serverconfig.dart';
import 'package:target_classic/constants.dart';
import 'package:path/path.dart' as p;

import 'package:target_classic/datatypes.dart';
import 'package:target_classic/entity.dart';
import 'package:target_classic/networking/heartbeat.dart';
import 'package:target_classic/networking/server.dart';
import 'package:target_classic/player.dart';
import 'package:target_classic/registries/commandregistry.dart';
import 'package:target_classic/registries/incrementalregistry.dart';
import 'package:target_classic/world.dart';
import 'package:target_classic/worldformats/hworld.dart';
import 'package:target_classic/registries/namedregistry.dart';
import 'package:target_classic/registries/worldregistry.dart';

typedef PlayerRegistry = NamedRegistry<String, Player>;
typedef EntityRegistry = IncrementalRegistry<Entity>;

class ServerConfiguration {
  final ServerConfig serverConfig;
  ServerConfiguration({required this.serverConfig});
}

class ServerRegistries {
  // FIXME: Quite verbose, maybe find a macro or build tool?
  final PlayerRegistry playerRegistry;
  final EntityRegistry entityRegistry;
  final WorldRegistry worldRegistry;
  final CommandRegistry commandRegistry;
  ServerRegistries({
    PlayerRegistry? playerRegistry,
    EntityRegistry? entityRegistry,
    WorldRegistry? worldRegistry,
    CommandRegistry? commandRegistry,
  }) : playerRegistry = playerRegistry ?? PlayerRegistry(),
       entityRegistry = entityRegistry ?? EntityRegistry(),
       worldRegistry = worldRegistry ?? WorldRegistry(),
       commandRegistry = commandRegistry ?? CommandRegistry();
}

class ServerContext {
  Chatroom? defaultChatroom; // FIXME: Consider making final
  Server? server;
  SaltManager? saltManager;
  Heartbeat? heartbeat;
  final ServerConfiguration configuration;
  final ServerRegistries registries;

  ServerContext({
    required this.configuration,
    ServerRegistries? registries,
    this.defaultChatroom,
    this.server,
    this.saltManager,
    this.heartbeat,
  }) : registries = registries ?? ServerRegistries();

  static Future<ServerContext> defaultContext() async {
    late final ServerConfiguration configuration;
    try {
      // FIXME: Needs redesigning for new config files
      configuration = ServerConfiguration(
        serverConfig: await ServerConfig.loadFromFile(),
      );
    } catch (e) {
      Logger.root.warning("Failed to load config: $e");
      configuration = ServerConfiguration(serverConfig: ServerConfig());
    }
    configuration.serverConfig.saveToFile();
    final registries = ServerRegistries();
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
    registries.worldRegistry.setDefaultWorld(defaultWorld);
    final SaltManager saltManager = await SaltManager.tryFromFile();
    saltManager.cacheSalt();

    final Heartbeat heartbeat = Heartbeat(
      heartbeatUrl: configuration.serverConfig.heartbeatUrl,
      serverConfig: configuration.serverConfig,
      salt: saltManager.salt,
      playerRegistry: registries.playerRegistry,
    );
    ServerContext context = ServerContext(
      configuration: configuration,
      registries: registries,
      heartbeat: heartbeat,
      saltManager: saltManager,
      defaultChatroom: Chatroom(name: "default"),
    );

    registries.playerRegistry.emitter.on("register", (Player player) {
      context.defaultChatroom?.addPlayer(player);
      player.emitter.on("destroy", (data) {
        context.defaultChatroom?.removePlayer(player);
      });
    });

    context.server = Server(
      configuration.serverConfig.host,
      configuration.serverConfig.port,
      context: context,
    );

    return context;
  }
}

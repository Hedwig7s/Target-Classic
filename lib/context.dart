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

class ServerContext {
  ServerConfig? serverConfig;
  PlayerRegistry? playerRegistry;
  EntityRegistry? entityRegistry;
  WorldRegistry? worldRegistry;
  Chatroom? defaultChatroom;
  Server? server;
  SaltManager? saltManager;
  Heartbeat? heartbeat;
  CommandRegistry? commandRegistry;

  static Future<ServerContext> defaultContext() async {
    ServerContext context = ServerContext();
    try {
      context.serverConfig = await ServerConfig.loadFromFile();
    } catch (e) {
      Logger.root.warning("Failed to load config: $e");
      context.serverConfig = ServerConfig();
    }
    context.serverConfig!.saveToFile();

    context.saltManager = await SaltManager.tryFromFile();
    context.saltManager?.cacheSalt();

    context.entityRegistry = EntityRegistry();
    context.playerRegistry = PlayerRegistry();

    context.heartbeat = Heartbeat(
      heartbeatUrl: context.serverConfig!.heartbeatUrl,
      serverConfig: context.serverConfig!,
      salt: context.saltManager!.salt,
      playerRegistry: context.playerRegistry!,
    );

    context.worldRegistry = WorldRegistry();
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
    context.worldRegistry!.setDefaultWorld(defaultWorld);

    context.defaultChatroom = Chatroom(name: "default");

    context.playerRegistry!.emitter.on("register", (Player player) {
      context.defaultChatroom?.addPlayer(player);
      player.emitter.on("destroy", (data) {
        context.defaultChatroom?.removePlayer(player);
      });
    });

    context.server = Server(
      context.serverConfig!.host,
      context.serverConfig!.port,
      context: context,
    );
    context.commandRegistry = CommandRegistry();

    return context;
  }
}

import 'dart:io';

import 'package:logging/logging.dart';
import 'chatroom.dart';

import 'config/serverconfig.dart';
import 'constants.dart';
import 'package:path/path.dart' as p;

import 'datatypes.dart';
import 'networking/server.dart';
import 'player.dart';
import 'world.dart';
import 'worldformats/hworld.dart';
import 'registries/namedregistry.dart';
import 'registries/worldregistry.dart';

typedef PlayerRegistry = NamedRegistry<String, Player>;

class ServerContext {
  ServerConfig? serverConfig;
  PlayerRegistry? playerRegistry;
  WorldRegistry? worldRegistry;
  Chatroom? defaultChatroom;
  Server? server;
  static Future<ServerContext> defaultContext() async {
    ServerContext context = ServerContext();
    try {
      context.serverConfig = await ServerConfig.loadFromFile();
    } catch (e) {
      Logger.root.warning("Failed to load config: $e");
      context.serverConfig = ServerConfig();
    }
    context.serverConfig!.saveToFile();

    context.playerRegistry = PlayerRegistry();

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

    context.server = new Server(
      context.serverConfig!.host,
      context.serverConfig!.port,
      context: context,
    );
    return context;
  }
}

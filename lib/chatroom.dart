import 'package:events_emitter/events_emitter.dart';
import 'package:logging/logging.dart';
import 'package:target_classic/registries/namedregistry.dart';

import 'package:target_classic/player.dart';

class Chatroom implements Nameable<String> {
  final Set<Player> players = {};
  @override
  final String name;
  final EventEmitter emitter = EventEmitter();
  final Logger logger;

  Chatroom({this.name = "default"})
    : assert(name.isNotEmpty, "Name must not be empty"),
      logger = Logger("Chatroom $name");

  void addPlayer(Player player) {
    players.add(player);
    player.chatroom = this;
    emitter.emit("playerAdded", player);
  }

  void removePlayer(Player player) {
    players.remove(player);
    if (player.chatroom == this) player.chatroom = null;
    emitter.emit("playerRemoved", player);
  }

  void sendMessage(Player? sender, String message) {
    logger.info("Message from ${sender?.name ?? "server"}: $message");
    if (!players.contains(sender)) return;
    if (message.isEmpty) return;
    emitter.emit("message", (sender: sender, message: message));

    for (var player in players) {
      player.sendMessage(
        "${sender != null ? "${sender.fancyName}&f: " : ""}$message",
      );
    }
  }
}

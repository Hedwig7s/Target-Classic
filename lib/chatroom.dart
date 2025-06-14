import 'package:events_emitter/events_emitter.dart';
import 'package:logging/logging.dart';
import 'package:target_classic/colorcodes.dart';
import 'package:target_classic/cooldown.dart';
import 'package:target_classic/message.dart';
import 'package:target_classic/registries/namedregistry.dart';

import 'package:target_classic/player.dart';

class Chatroom implements Nameable<String> {
  final Set<Player> players = {};
  @override
  final String name;
  final EventEmitter emitter = EventEmitter();
  final Logger logger;
  final Duration cooldownResetTime;
  final int cooldownLimit;
  final Map<Player, Cooldown> cooldowns = {};

  Chatroom({
    this.name = "default",
    this.cooldownResetTime = const Duration(seconds: 3),
    this.cooldownLimit = 5,
  }) : assert(name.isNotEmpty, "Name must not be empty"),
       logger = Logger("Chatroom $name");

  void addPlayer(Player player) {
    players.add(player);
    player.chatroom = this;
    emitter.emit("playerAdded", player);
    cooldowns[player] = Cooldown(
      maxCount: cooldownLimit,
      resetTime: cooldownResetTime,
    );
  }

  void removePlayer(Player player) {
    players.remove(player);
    cooldowns.remove(player);
    if (player.chatroom == this) player.chatroom = null;
    emitter.emit("playerRemoved", player);
  }

  void sendMessage(
    Player? sender,
    Message message, {
    bool bypassCooldown = false,
  }) {
    if (sender != null && !bypassCooldown && !cooldowns[sender]!.canUse()) {
      logger.warning("${sender.name} is on cooldown!");
      sender.sendMessage(
        Message("${ColorCodes.red}You're sending messages too fast!"),
      );
      return;
    }
    logger.info("Message from ${sender?.name ?? "server"}: $message");
    if (!players.contains(sender)) return;
    if (message.message.isEmpty) return;
    emitter.emit("message", (sender: sender, message: message));

    for (var player in players) {
      player.sendMessage(
        Message(
          "${sender != null ? "${sender.fancyName}${ColorCodes.white}: " : ""}$message",
        ),
      );
    }
  }
}

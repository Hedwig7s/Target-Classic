import 'package:target_classic/chat/message.dart';
import 'package:target_classic/commands/command.dart';
import 'package:target_classic/commands/parameters/parameters.dart';
import 'package:target_classic/commands/parameters/parser.dart';
import 'package:target_classic/context.dart';
import 'package:target_classic/player.dart';

void registerGetPlayer(ServerContext serverContext) {
  var command = ParsedCommand(
    name: "getplayer",
    summary: "Gets information about an entity",
    permission: "getplayer",
    root: literal("getplayer").then(
      parameter(PlayerParameter("Player")).executes((context, args) {
            var player = args[1] as Player;
            context.player.sendMessage(
              Message(
                "Player ${player.name}\nName: ${player.name}\nFancy Name: ${player.fancyName}\nChatroom: ${player.chatroom?.name}\nWorld: ${player.world?.name}",
              ),
              "",
            );
          })
          as ParameterParser,
    ),
  );
  serverContext.commandRegistry?.register(command);
}

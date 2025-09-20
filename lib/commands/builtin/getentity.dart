import 'package:target_classic/chat/message.dart';
import 'package:target_classic/commands/command.dart';
import 'package:target_classic/commands/parameters/parameters.dart';
import 'package:target_classic/commands/parameters/parser.dart';
import 'package:target_classic/context.dart';
import 'package:target_classic/entity.dart';

void registerGetEntity(ServerContext serverContext) {
  var command = ParsedCommand(
    name: "getentity",
    summary: "Gets information about an entity",
    permission: "getentity",
    parser: parameter(EntityParameter("Entity")).executes((
      CommandContext context,
      List<dynamic> args,
    ) {
      var entity = args[0] as Entity;
      int? id = entity.ids[context.serverContext?.entityRegistry];
      context.player.sendMessage(
        Message(
          "Entity $id\nName: ${entity.name}\nID: $id\nFancy Name: ${entity.fancyName}",
        ),
        "",
      );
    }),
  );
  serverContext.commandRegistry?.register(command);
}

import 'package:target_classic/chat/message.dart';
import 'package:target_classic/commands/command.dart';
import 'package:target_classic/commands/parameters/parser.dart';
import 'package:target_classic/context.dart';

void registerListEntities(ServerContext serverContext) {
  var command = ParsedCommand(
    name: "listentities",
    summary: "Gets entities",
    permission: "listentities",
    root: literal("listentities").executes((
      CommandContext context,
      List<dynamic> args,
    ) {

      var entityRegistry = context.serverContext.registries.entityRegistry;
      for (int i = 0; i < entityRegistry.length; i++) {
        var entity = entityRegistry.get(i)!;
        context.player.sendMessage(
          Message("${entity.ids[entityRegistry]!}: ${entity.name}"),
          "",
        );
      }
    }),
  );
  serverContext.registries.commandRegistry.register(command);
}

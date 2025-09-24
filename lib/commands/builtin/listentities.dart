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
      if (context.serverContext?.entityRegistry == null) {
        throw CommandStateException("No entity registry present");
      }
      var entityRegistry = context.serverContext!.entityRegistry!;
      for (int i = 0; i < entityRegistry.length; i++) {
        var entity = entityRegistry.get(i)!;
        context.player.sendMessage(
          Message("${entity.ids[entityRegistry]!}: ${entity.name}"),
          "",
        );
      }
    }),
  );
  serverContext.commandRegistry?.register(command);
}

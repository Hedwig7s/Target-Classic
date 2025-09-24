import 'package:logging/logging.dart';
import 'package:target_classic/chat/message.dart';
import 'package:target_classic/colorcodes.dart';
import 'package:target_classic/commands/command.dart';
import 'package:target_classic/entity.dart';
import 'package:target_classic/player.dart';

class CommandRegistry {
  final Set<Command> commands = {};
  final Map<String, Command> aliases = {};
  void register(Command command) {
    for (var alias in command.aliases) {
      if (aliases.containsKey(alias)) {
        throw Exception("Duplicate command $alias");
      }
    }
    commands.add(command);
    for (var alias in command.aliases) {
      aliases[alias] = command;
    }
  }

  void unregister(Command command) {
    commands.remove(command);
    for (var alias in command.aliases) {
      if (aliases.containsKey(alias) && aliases[alias]! == command) {
        aliases.remove(alias);
      }
    }
  }

  Command? getCommand(String alias) {
    return aliases[alias];
  }

  void dispatch({
    required String rawCommand,
    required Player player,
    Entity? entity,
  }) {
    List<String> args = rawCommand.substring(1).split(" ");
    String alias = args[0];
    Command? command = getCommand(alias);
    if (command == null) {
      player.sendMessage(
        Message("${ColorCodes.red}Unknown command: $alias"),
      ); // TODO: Maybe try to find closest match and ask if that's what player meant
      return;
    }
    CommandContext context = CommandContext(
      player: player,
      rawCommand: rawCommand,
      startingArgs: args,
      entity: entity ?? player.entity,
      serverContext: player.context,
    );
    try {
      command.execute(context);
    } catch (e, stackTrace) {
      if (e is CommandException) {
        player.sendMessage(Message("${ColorCodes.red}${e.message}"));
      } else {
        player.sendMessage(Message("${ColorCodes.red}Internal Server Error"));
      }
      command.logger.log(
        e is CommandException ? Level.WARNING : Level.SEVERE,
        "${e is CommandException ? (e.internalMessage ?? e.message) : e}\n$stackTrace",
      );
    }
  }
}

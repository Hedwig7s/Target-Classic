import 'package:logging/logging.dart';
import 'package:target_classic/commands/parameters/parameters.dart';
import 'package:target_classic/commands/parameters/parser.dart';
import 'package:target_classic/context.dart';
import 'package:target_classic/entity.dart';
import 'package:target_classic/player.dart';

class CommandException implements Exception {
  String message;
  String? internalMessage;
  CommandException(this.message, [this.internalMessage]);
  @override
  String toString() {
    return message;
  }
}

class CommandSyntaxException extends CommandException {
  CommandSyntaxException(super.message, [super.internalMessage]);
}

class CommandOutOfArgsException extends CommandSyntaxException {
  CommandOutOfArgsException([
    super.message = "Not enough arguments",
    super.internalMessage,
  ]);
}

class CommandStateException extends CommandException {
  CommandStateException(super.message, [super.internalMessage]);
}

class CommandCallerHasNoEntityException extends CommandStateException {
  CommandCallerHasNoEntityException([
    super.message = "No entity associated with caller",
  ]);
}

class CommandContext {
  final String rawCommand;
  final List<String> startingArgs;
  final ServerContext serverContext;
  final Entity? entity;
  final Player player;
  int argIndex = 0;
  int charIndex = 0;
  List<String> args;
  List<dynamic> parsedValues;

  CommandContext({
    required this.serverContext,
    required this.player,
    required this.rawCommand,
    required this.startingArgs,
    this.entity,
    List<dynamic>? out,
    List<String>? args,
  }) : args = args ?? List.from(startingArgs),
       parsedValues = out ?? [];
  CommandContext clone() {
    return CommandContext(
      serverContext: serverContext,
      entity: entity,
      player: player,
      rawCommand: rawCommand,
      startingArgs: List.from(startingArgs),
      args: List.from(args),
      out: List.from(parsedValues),
    );
  }
}

abstract class Command {
  String get name;
  String get summary;
  String get description;
  String get permission;
  Logger get logger;
  Map<String, dynamic> getValues() {
    return {
      "name": name,
      "summary": summary,
      "description": description,
      "permission": permission,
    };
  }

  Set<String> get aliases;

  String syntax();
  void execute(CommandContext context);
}

class ParsedCommand extends Command {
  RootParser root;
  @override
  final String name;
  @override
  final Set<String> aliases;
  @override
  final String summary;
  @override
  final String description;
  @override
  final String permission;
  @override
  final Logger logger;

  ParsedCommand({
    required this.name,
    required this.summary,
    String? description,
    required this.permission,
    required this.root,
    Logger? logger,
  }) : description = description ?? summary,
       aliases = {},
       logger = logger ?? Logger("Command $name") {
    if (root is ParameterParser && root is! ParameterParser<LiteralParameter>) {
      throw ArgumentError.value(
        root,
        "root",
        "Root must be RootParser or ParameterParser<LiteralParameter>",
      );
    } else if (root is ParameterParser<LiteralParameter>) {
      aliases.add((root as ParameterParser).parameter.name);
    } else {
      for (var branch in root.branches) {
        if (branch is ParameterParser<LiteralParameter>) {
          aliases.add(branch.parameter.name);
        } else {
          throw ArgumentError(
            "Root may only be followed by literal nodes. Found ${branch.runtimeType}",
          );
        }
      }
    }
    for (var alias in aliases) {
      if (!RegExp(r"^[a-zA-Z0-9]+$").hasMatch(alias)) {
        throw Exception(
          "Alias has invalid characters. Commands may only contain alphanumeric characters",
        );
      }
    }
  }

  @override
  void execute(CommandContext context) {
    int executed = root.execute(context);
    if (executed <= 0) {
      throw Exception("Nothing provided to execute!");
    }
    return;
  }

  @override
  String syntax() {
    return root.syntax().map((var syntax) => "/$syntax").join();
  }
}

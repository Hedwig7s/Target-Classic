import 'package:target_classic/commands/parameters/parser.dart';

abstract class CommandException implements Exception {
  String message;
  CommandException(this.message);
}

class CommandSyntaxException extends CommandException {
  CommandSyntaxException(super.message);
}

class CommandOutOfArgsException extends CommandSyntaxException {
  CommandOutOfArgsException([super.message = "Not enough arguments"]);
}

class Command {
  final String name;
  final String summary;
  final String description;
  final String permission;
  final ParameterParser? parser;

  Command(
    this.name,
    this.summary,
    this.description,
    this.permission,
    this.parser,
  );

  void execute(List<String> args) {
    if (this.parser != null) {
      int executed = this.parser!.execute(args);
      if (executed <= 0) {
        throw Exception("Nothing provided to execute!");
      }
      return;
    }
    throw Exception(
      "No parser set up to execute! Please add a parser or override the execute method.",
    );
  }

  String syntax() {
    if (parser != null) {
      return parser!.syntax().map((var syntax) => "/${syntax}").join();
    }
    return "No syntax available! If no parser defined, add a parser or override the syntax method";
  }
}

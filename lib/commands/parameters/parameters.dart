import 'package:target_classic/commands/command.dart';

typedef ParseResult = ({List<String> args, List<dynamic> out});

const REQUIRED_PARAM_OPEN = "<";
const REQUIRED_PARAM_CLOSE = ">";

const OPTIONAL_LITERAL_OPEN = "[";
const OPTIONAL_LITERAL_CLOSE = "]";

const OPTIONAL_PARAM_OPEN = "[<";
const OPTIONAL_PARAM_CLOSE = ">]";

abstract class Parameter {
  String get type;
  final String name;
  final bool optional;
  Parameter(this.name, [this.optional = false]);
  ParseResult parse(List<String> args, List<dynamic> out);
  @override
  bool operator ==(Object other) {
    return identical(other, this) ||
        other is Parameter &&
            type == other.type &&
            name == other.name &&
            optional == other.optional;
  }

  String syntax() {
    return "${optional ? OPTIONAL_PARAM_OPEN : REQUIRED_PARAM_OPEN}$name: $type${optional ? OPTIONAL_PARAM_CLOSE : REQUIRED_PARAM_CLOSE}";
  }
}

void checkArgs(List<String> args, {int requiredEntries = 1}) {
  if (args.length >= requiredEntries) return;
  if (args.length == 1) throw CommandOutOfArgsException();
  throw CommandSyntaxException(
    "Incomplete argument. Expected $requiredEntries args. Got ${args.length}",
  );
}

class StringParameter extends Parameter {
  final String type = "String";
  StringParameter(super.name, [super.optional = false]);
  ParseResult parse(List<String> args, List<dynamic> out) {
    checkArgs(args);
    out.add(args.removeAt(0)); // TODO: Quote support
    return (args: args, out: out);
  }
}

class LiteralParameter extends Parameter {
  final String type = "Literal";
  LiteralParameter(super.name, [super.optional = false]);
  ParseResult parse(List<String> args, List<dynamic> out) {
    checkArgs(args);
    String arg = args.removeAt(0);
    if (arg != name)
      throw CommandSyntaxException("Value $arg is not the literal $name");
    out.add(arg);
    return (args: args, out: out);
  }

  @override
  String syntax() {
    return "${optional ? OPTIONAL_LITERAL_OPEN : REQUIRED_PARAM_OPEN}$name${optional ? OPTIONAL_LITERAL_OPEN : REQUIRED_PARAM_CLOSE}";
  }
}

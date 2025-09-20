// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:characters/characters.dart';
import 'package:target_classic/commands/command.dart';
import 'package:target_classic/datatypes.dart';

const REQUIRED_PARAM_OPEN = "<";
const REQUIRED_PARAM_CLOSE = ">";

const OPTIONAL_LITERAL_OPEN = "[";
const OPTIONAL_LITERAL_CLOSE = "]";

const OPTIONAL_PARAM_OPEN = "[<";
const OPTIONAL_PARAM_CLOSE = ">]";

const RELATIVE_COORDINATE_INDICATOR = "~";

abstract class Parameter {
  String get type;
  final String name;
  final bool optional;
  Parameter(this.name, [this.optional = false]);
  CommandContext parse(CommandContext context);
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
  if (args.isEmpty)
    throw CommandOutOfArgsException(); // FIXME: Potentially add a more specific count
  throw CommandSyntaxException(
    "Incomplete argument. Needed $requiredEntries arguments, got ${args.length}",
  );
}

int _assertInt(List<String> args) {
  String arg = args.removeAt(0);
  int? value = int.tryParse(arg);
  if (value == null) throw CommandSyntaxException('Invalid integer "$arg".');
  return value;
}

double _assertDouble(List<String> args) {
  String arg = args.removeAt(0);
  double? value = double.tryParse(arg);
  if (value == null) throw CommandSyntaxException('Invalid double "$arg".');
  return value;
}

bool isRelativeCoord(String arg) =>
    arg.startsWith(RELATIVE_COORDINATE_INDICATOR);

enum CoordIteration { x, y, z, yaw, pitch }

num resolveCoordinate(
  CommandContext context,
  String arg,
  CoordIteration iteration, [
  bool isInt = false,
]) {
  if (!isRelativeCoord(arg)) {
    if (isInt || iteration.index > 2) {
      int? value = int.tryParse(arg);
      if (value == null)
        throw CommandSyntaxException('Invalid integer "$arg".');
      return value;
    } else {
      double? value = double.tryParse(arg);
      if (value == null) throw CommandSyntaxException('Invalid double "$arg".');
      return value;
    }
  }
  if (context.entity == null) throw CommandCallerHasNoEntityException();
  EntityPosition entityPosition = context.entity!.position;
  num offset = 0;
  if (arg.length > 1) {
    String invalidOffsetError =
        "Invalid number after $RELATIVE_COORDINATE_INDICATOR: ${arg.substring(1)}";
    if (iteration.index < 3 && !isInt) {
      // It's a position coordinate and not an int
      double? parsed = double.tryParse(arg.substring(1));
      if (parsed == null) throw CommandSyntaxException(invalidOffsetError);
      offset = parsed;
    } else {
      // It's yaw or pitch, or int coordinate
      int? parsed = int.tryParse(arg.substring(1));
      if (parsed == null) throw CommandSyntaxException(invalidOffsetError);
      offset = parsed;
    }
  }
  switch (iteration) {
    case (CoordIteration.x):
      {
        if (isInt)
          return (entityPosition.x + offset).floor();
        else
          return entityPosition.x + offset;
      }
    case (CoordIteration.y):
      {
        if (isInt)
          return (entityPosition.y + offset).floor();
        else
          return entityPosition.y + offset;
      }
    case (CoordIteration.z):
      {
        if (isInt)
          return (entityPosition.z + offset).floor();
        else
          return entityPosition.z + offset;
      }
    case (CoordIteration.yaw):
      {
        return entityPosition.yaw + offset.toInt();
      }
    case (CoordIteration.pitch):
      {
        return entityPosition.pitch + offset.toInt();
      }
  }
}

class StringParameter extends Parameter {
  @override
  final String type = "String";
  StringParameter(super.name, [super.optional = false]);
  @override
  CommandContext parse(CommandContext context) {
    var args = context.args;
    var out = context.parsedValues;
    checkArgs(args);
    if (args[0].startsWith('"')) {
      String currentArg = args.removeAt(0).substring(1);
      bool closed = false;
      List<String> parts = [];
      while (args.isNotEmpty) {
        bool escaped = false;
        for (var (index, char) in currentArg.characters.indexed) {
          if (char == '"' && !escaped) {
            closed = true;
            if (index != currentArg.length - 1)
              throw CommandSyntaxException(
                'Invalid character in "$currentArg". " must be at end of text segment or be escaped via \\".', // FIXME: Probably good idea to add a proper way to get the index of the character
              );
            currentArg = currentArg.substring(0, currentArg.length - 1);
            break;
          } else if (char == "\\" && !escaped) {
            escaped = true;
          } else if (escaped) {
            escaped = false;
          }
        }
        parts.add(currentArg);
        if (closed) break;
        currentArg = args.removeAt(0);
      }
      if (!closed) throw CommandSyntaxException("Unterminated string.");
      out.add(parts.join(" "));
    } else {
      String arg = args.removeAt(0);
      if (arg.contains('"')) {
        bool escaped = false;
        for (var char in arg.characters) {
          if (char == '"' && !escaped) {
            throw CommandSyntaxException(
              'Invalid character in "$arg". " can not be within a string argument without being at the start or being escaped via \\".',
            );
          } else if (char == "\\" && !escaped) {
            escaped = true;
          } else if (escaped) {
            escaped = false;
          }
        }
      }
      out.add(arg);
    }
    return context;
  }
}

class LiteralParameter extends Parameter {
  @override
  final String type = "Literal";
  LiteralParameter(super.name, [super.optional = false]);
  @override
  CommandContext parse(CommandContext context) {
    var args = context.args;
    var out = context.parsedValues;
    checkArgs(args);
    String arg = args.removeAt(0);
    if (arg != name)
      throw CommandSyntaxException("Value $arg is not the literal $name");
    out.add(arg);
    return context;
  }

  @override
  String syntax() {
    return "${optional ? OPTIONAL_LITERAL_OPEN : REQUIRED_PARAM_OPEN}$name${optional ? OPTIONAL_LITERAL_OPEN : REQUIRED_PARAM_CLOSE}";
  }
}

class OptionParameter extends Parameter {
  @override
  final String type = "Option";
  final Set<String> options;
  OptionParameter(this.options, super.name, [super.optional = false])
    : assert(options.isNotEmpty);
  @override
  CommandContext parse(CommandContext context) {
    var args = context.args;
    var out = context.parsedValues;
    checkArgs(args);
    String arg = args.removeAt(0);
    if (!options.contains(arg))
      throw CommandSyntaxException("Value $arg is not the literal $name");
    out.add(arg);
    return context;
  }

  @override
  String syntax() {
    return "${optional ? OPTIONAL_LITERAL_OPEN : REQUIRED_PARAM_OPEN}$name: $type ${options.join("|")}${optional ? OPTIONAL_LITERAL_OPEN : REQUIRED_PARAM_CLOSE}";
  }
}
class IntParameter extends Parameter {
  @override
  final String type = "int";
  IntParameter(super.name, [super.optional = false]);
  @override
  CommandContext parse(CommandContext context) {
    var args = context.args;
    var out = context.parsedValues;
    out.add(_assertInt(args));
    return context;
  }
}

class DoubleParameter extends Parameter {
  @override
  final String type = "double";
  DoubleParameter(super.name, [super.optional = false]);
  @override
  CommandContext parse(CommandContext context) {
    var args = context.args;
    var out = context.parsedValues;
    out.add(_assertDouble(args));
    return context;
  }
}

class Vector3Parameter extends Parameter {
  @override
  final String type = "Vector3";
  final bool isFloat;
  Vector3Parameter(super.name, this.isFloat, [super.optional = false]);
  @override
  CommandContext parse(CommandContext context) {
    var args = context.args;
    var out = context.parsedValues;
    checkArgs(args, requiredEntries: 3);
    final Vector3 vector3;
    if (isFloat) {
      List<double> coords = [];
      for (int i = 0; i < 3; i++) {
        coords.add(
          resolveCoordinate(
            context,
            args.removeAt(0),
            CoordIteration.values[i],
          ).toDouble(),
        );
      }
      vector3 = Vector3F(coords[0], coords[1], coords[2]);
    } else {
      List<int> coords = [];
      for (int i = 0; i < 3; i++) {
        coords.add(
          resolveCoordinate(
            context,
            args.removeAt(0),
            CoordIteration.values[i],
          ).toInt(),
        );
      }
      vector3 = Vector3I(coords[0], coords[1], coords[2]);
    }
    out.add(vector3);
    return context;
  }
}

class EntityPositionParameter extends Parameter {
  @override
  final String type = "Vector3";
  EntityPositionParameter(super.name, [super.optional = false]);
  @override
  CommandContext parse(CommandContext context) {
    var args = context.args;
    var out = context.parsedValues;
    checkArgs(args, requiredEntries: 5);
    List<num> coords = [];
    for (int i = 0; i < 5; i++) {
      coords.add(
        resolveCoordinate(context, args.removeAt(0), CoordIteration.values[i]),
      );
    }
    out.add(
      EntityPosition(
        coords[0].toDouble(),
        coords[1].toDouble(),
        coords[2].toDouble(),
        coords[3].toInt(),
        coords[4].toInt(),
      ),
    );
    return context;
  }
}

class EntityParameter extends Parameter {
  @override
  final String type = "Entity";
  EntityParameter(super.name, [super.optional]);
  @override
  CommandContext parse(CommandContext context) {
    var entityRegistry = context.serverContext?.entityRegistry;
    if (entityRegistry == null)
      throw CommandStateException("No entity registry present.");
    var args = context.args;
    var out = context.parsedValues;
    int id = _assertInt(args);
    if (!entityRegistry.contains(id)) throw Exception("Entity $id not found.");
    out.add(entityRegistry.get(id));
    return context;
  }
}

class PlayerParameter extends Parameter {
  @override
  final String type = "Player";
  PlayerParameter(super.name, [super.optional]);
  @override
  CommandContext parse(CommandContext context) {
    var playerRegistry = context.serverContext?.playerRegistry;
    if (playerRegistry == null)
      throw CommandStateException("No player registry present.");
    var args = context.args;
    var out = context.parsedValues;
    String name = args.removeAt(0);
    if (!playerRegistry.contains(name))
      throw Exception("Player $name not found.");
    out.add(playerRegistry.get(name));
    return context;
  }
}

class WorldParameter extends Parameter {
  @override
  final String type = "World";
  WorldParameter(super.name, [super.optional]);
  @override
  CommandContext parse(CommandContext context) {
    var worldRegistry = context.serverContext?.worldRegistry;
    if (worldRegistry == null)
      throw CommandStateException("No world registry present.");
    var args = context.args;
    var out = context.parsedValues;
    String name = args.removeAt(0);
    if (!worldRegistry.contains(name))
      throw Exception("World $name not found.");
    out.add(worldRegistry.get(name));
    return context;
  }
}

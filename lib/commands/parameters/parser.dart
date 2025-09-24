import 'package:target_classic/commands/command.dart';
import 'package:target_classic/commands/parameters/parameters.dart';

class ParameterBranch {
  final RootParser branch;
  int current = 0;
  ParameterBranch(this.branch)
    : assert(branch.branches.isNotEmpty, "Branch must not be empty");
}

ParameterParser<T> parameter<T extends Parameter>(T parameter) {
  return ParameterParser(parameter);
}

ParameterParser<LiteralParameter> literal(String literal) {
  return parameter(LiteralParameter(literal));
}

ParameterParser<OptionParameter> option(Set<String> options, String name) {
  return parameter(OptionParameter(options, name));
}

RootParser root() {
  return RootParser();
}

class ParameterParser<T extends Parameter> extends RootParser {
  final T parameter;
  ParameterParser(this.parameter);
  @override
  RootParser then(ParameterParser<Parameter> node) {
    if (parameter.optional && !node.parameter.optional) {
      throw ArgumentError("Cannot have a required parameter after an optional");
    }
    return super.then(node);
  }

  @override
  bool operator ==(Object other) {
    return other is ParameterParser && other.parameter == parameter;
  }
}

class RootParser {
  final List<ParameterParser> branches = [];
  bool get isLeaf => branches.isEmpty;
  bool get isSegment => branches.length == 1;
  bool get isFork => branches.length > 1;
  void Function(CommandContext context, List<dynamic> args)? willExecute;

  RootParser then(ParameterParser node) {
    for (var branch in branches) {
      if (node == branch) {
        return this;
      }
    }

    branches.add(node);
    return this;
  }

  RootParser executes(
    void Function(CommandContext context, List<dynamic> args) toExecute,
  ) {
    willExecute = toExecute;
    return this;
  }

  int execute(CommandContext context) {
    return _parse(context, true).executed;
  }

  List<String> syntax() {
    Map<Parameter, String> cache = {};
    String getSyntax(Parameter parameter) {
      if (cache.containsKey(parameter)) return cache[parameter]!;
      String value = parameter.syntax();
      cache[parameter] = value;
      return value;
    }

    int i = 0;
    List<String> handleNode(RootParser node) {
      if (i >= 300) throw Exception("Too many iterations!");
      i++;
      if (node is ParameterParser) {
        String syntax = getSyntax(node.parameter); // <example>
        if (node.isLeaf) return [syntax];
      }
      List<String> paths = [];
      for (var branch in node.branches) {
        var subPaths = handleNode(
          branch,
        ); // [<example2>, <example2> [<example3>]]
        for (var path in subPaths) {
          paths.add(
            "$syntax $path",
          ); // 0: <example> <example2>, 1: <example> <example2> [<example3>]
        }
      }
      return paths;
    }

    return handleNode(this);
  }

  ({RootParser finalNode, int executed, CommandContext context}) _parse(
    CommandContext context, [
    bool shouldExecute = false,
  ]) {
    List<ParameterBranch> branchStack = [];
    int deepestPath = 0;
    int depth = 0;
    CommandException? deepestException;
    RootParser node = this;
    int executed = 0;
    context = context.clone();
    for (int i = 0; ; i++) {
      if (i >= 300) throw Exception("Too many iterations");
      if (node is ParameterParser) {
        try {
          Parameter parameter = node.parameter;
          context = parameter.parse(context.clone());
        } on CommandException catch (e, stackTrace) {
          if (depth >= deepestPath) deepestException = e;
          ParameterBranch? lastBranch;
          ParameterParser? nextNode;
          while (true) {
            lastBranch = branchStack.lastOrNull;
            if (lastBranch == null) {
              Error.throwWithStackTrace(
                CommandSyntaxException(
                  "Failed to parse command:\n${deepestException?.message ?? "Unknown error"}",
                  "Failed to find valid path for command ${context.rawCommand}: Deepest exception: ${deepestException?.internalMessage ?? deepestException?.message ?? "Unknown error"}",
                ),
                stackTrace,
              );
            }
            nextNode = lastBranch.branch.branches.elementAtOrNull(
              lastBranch.current++,
            );
            if (nextNode == null) {
              branchStack.removeLast();
              depth--;
              continue;
            }
            break;
          }
          node = nextNode;

          continue;
        }
      }
      if (node.willExecute != null && shouldExecute) {
        node.willExecute!(context.clone(), context.parsedValues);
        executed++;
      }
      if (node.isLeaf) {
        break;
      }
      branchStack.add(ParameterBranch(node));
      node = node.branches[0];
      depth++;
      if (depth > deepestPath) deepestPath = depth;
    }
    return (finalNode: node, executed: executed, context: context);
  }

  List<dynamic> parse(CommandContext context) {
    return _parse(context).context.parsedValues;
  }
}

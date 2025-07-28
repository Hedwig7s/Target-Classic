import 'package:target_classic/commands/command.dart';
import 'package:target_classic/commands/parameters/parameters.dart';

class ParameterBranch {
  final ParameterParser branch;
  int current = 0;
  ParameterBranch(this.branch)
    : assert(branch.branches.isNotEmpty, "Branch must not be empty");
}

ParameterParser parameter(Parameter parameter) {
  return ParameterParser(parameter);
}

ParameterParser literal(String literal) {
  return ParameterParser(LiteralParameter(literal));
}

class ParameterParser {
  final List<ParameterParser> branches = [];
  bool get isLeaf => branches.isEmpty;
  bool get isSegment => branches.length == 1;
  bool get isFork => branches.length > 1;
  final Parameter parameter;
  void Function(List<dynamic> args)? willExecute;
  ParameterParser(this.parameter);
  ParameterParser then(ParameterParser node) {
    if (parameter.optional && !node.parameter.optional)
      throw ArgumentError("Cannot have a required parameter after an optional");
    for (var branch in branches) {
      if (node == branch) {
        return branch;
      }
    }

    branches.add(node);
    return this;
  }

  ParameterParser executes(void Function(List<dynamic> args) toExecute) {
    this.willExecute = toExecute;
    return this;
  }

  int execute(List<String> args) {
    return _parse(args, true).executed;
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
    List<String> handleNode(ParameterParser node) {
      if (i >= 300) throw Exception("Too many iterations!");
      i++;
      String syntax = getSyntax(node.parameter); // <example>
      if (node.isLeaf) return [syntax];
      List<String> paths = [];
      for (var branch in node.branches) {
        var subPaths = handleNode(
          branch,
        ); // [<example2>, <example2> [<example3>]]
        for (var path in subPaths) {
          paths.add(
            "$syntax $path",
          ); // 0: <example> <example2>, 1: <example> <example2> <example3>
        }
      }
      return paths;
    }

    return handleNode(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ParameterParser && other.parameter == parameter;
  }

  ({List<dynamic> out, ParameterParser node, int executed}) _parse(
    List<String> args, [
    bool shouldExecute = false,
  ]) {
    List<dynamic> out = [];
    List<ParameterBranch> branchStack = [];
    ParameterParser node = this;
    int executed = 0;
    for (int i = 0; ; i++) {
      if (i >= 300) throw Exception("Too many iterations");
      try {
        Parameter parameter = node.parameter;
        var result = parameter.parse(List.from(args), List.from(out));
        args = result.args;
        out = result.out;
      } on CommandSyntaxException catch (e, stackTrace) {
        if (e is CommandOutOfArgsException && node.parameter.optional) {
          break; // Optional parameter not fulfilled. Can just exit out.
        }
        ParameterBranch? lastBranch =
            branchStack.isNotEmpty ? branchStack.removeLast() : null;

        var branches = lastBranch?.branch.branches;
        if (lastBranch == null ||
            branches!.isEmpty ||
            branches.length <= lastBranch.current)
          Error.throwWithStackTrace(
            CommandSyntaxException(
              "Failed to parse command.\nLast Error: ${e.message}",
            ),
            stackTrace,
          );
        node = branches[++lastBranch.current];
        continue;
      }
      if (node.willExecute != null && shouldExecute) {
        node.willExecute!(args);
        executed++;
      }
      if (node.isSegment) {
        node = node.branches[0];
      } else if (node.isLeaf) {
        break;
      } else if (node.isFork) {
        var branch = ParameterBranch(node);
        branchStack.add(branch);
        node = branch.branch.branches[branch.current++];
      }
    }
    return (out: out, node: node, executed: executed);
  }

  List<dynamic> parse(List<String> args) {
    return _parse(args).out;
  }
}

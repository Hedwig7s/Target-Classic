import 'package:target_classic/chat/message.dart';
import 'package:target_classic/colorcodes.dart';
import 'package:target_classic/commands/command.dart';
import 'package:target_classic/commands/parameters/parameters.dart';
import 'package:target_classic/commands/parameters/parser.dart';
import 'package:target_classic/context.dart';
import 'package:target_classic/datatypes.dart';
import 'package:target_classic/entity.dart';
import 'package:target_classic/player.dart';

void registerTeleport(ServerContext serverContext) {
  void teleport(EntityPosition entityPosition, CommandContext context) {
    context.player.move(entityPosition);
    context.player.sendMessage(
      Message(
        "${ColorCodes.white}You have been teleported to ${entityPosition.x} ${entityPosition.y} ${entityPosition.z}",
      ),
    );
  }

  var rootNode = root();
  // TODO: Teleport entity or player to target

  var vector3Parser =
      parameter(Vector3Parameter("position", true)).executes((context, args) {
            teleport(
              EntityPosition.fromVector3(
                vector: args[1],
                yaw: context.player.entity?.position.yaw ?? 0,
                pitch: context.player.entity?.position.pitch ?? 0,
              ),
              context,
            );
          })
          as ParameterParser;
  var entityPositionParser =
      parameter(
            EntityPositionParameter("position"),
          ).executes((context, args) => teleport(args[1], context))
          as ParameterParser;

  var entityParser =
      parameter(EntityParameter("target")).executes(
            (context, args) => teleport((args[1] as Entity).position, context),
          )
          as ParameterParser;

  var playerParser =
      parameter(PlayerParameter("target")).executes((context, args) {
            var player = args[0] as Player;
            if (player.entity == null) {
              throw CommandStateException("Target has no entity");
            }
            teleport(player.entity!.position, context);
          })
          as ParameterParser;

  for (var alias in ["tp", "teleport"]) {
    var aliasNode =
        literal(alias)
                .then(vector3Parser)
                .then(entityPositionParser)
                .then(entityParser)
                .then(playerParser)
            as ParameterParser;
    rootNode.then(aliasNode);
  }

  var command = ParsedCommand(
    name: "teleport",
    summary: "Teleport to a coordinate",
    permission: "teleport",
    root: rootNode,
  );
  serverContext.commandRegistry?.register(command);
}

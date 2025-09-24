import 'package:target_classic/commands/builtin/getentity.dart';
import 'package:target_classic/commands/builtin/getplayer.dart';
import 'package:target_classic/commands/builtin/listentities.dart';
import 'package:target_classic/commands/builtin/teleport.dart';
import 'package:target_classic/context.dart';

void registerBuiltinCommands(ServerContext serverContext) {
  registerGetEntity(serverContext);
  registerListEntities(serverContext);
  registerGetPlayer(serverContext);
  registerTeleport(serverContext);
}

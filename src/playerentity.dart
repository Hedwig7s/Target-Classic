import 'datatypes.dart';
import 'entity.dart';
import 'networking/connection.dart';
import 'player.dart';
import 'world.dart';

class PlayerEntity extends Entity {
  Player player;
  PlayerEntity({required super.name, required this.player, super.fancyName}) {}

  @override
  spawn(World world, {calledBack = false}) {
    if (calledBack) {
      super.spawn(world);
      return;
    }
    this.player.loadWorld(world);
  }

  @override
  move(EntityPosition newPosition, {byPlayer = false}) {
    super.move(newPosition);
    if (!byPlayer) {
      // TODO: Teleport player
    }
  }

  @override
  spawnFor(Connection connection) {
    // TODO: implement spawnFor
  }
}

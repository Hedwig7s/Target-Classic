import 'package:target_classic/datatypes.dart';
import 'package:target_classic/entity.dart';
import 'package:target_classic/networking/connection.dart';
import 'package:target_classic/networking/packet.dart';
import 'package:target_classic/networking/protocol.dart';
import 'package:target_classic/networking/packetdata.dart';
import 'package:target_classic/player.dart';
import 'package:target_classic/world.dart';

class PlayerEntity extends Entity {
  Player player;
  PlayerEntity({
    required super.name,
    required this.player,
    super.fancyName,
    super.context,
  }) {}

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
    if (byPlayer && newPosition == position) {
      return;
    }
    super.move(newPosition);
    if (!byPlayer) {
      var packet = this.player.connection!.protocol!
          .assertPacket<SendablePacket<SetPositionAndOrientationPacketData>>(
            PacketIds.setPositionAndOrientation,
          );
      packet.send(
        this.player.connection!,
        SetPositionAndOrientationPacketData(
          playerId: this.worldId!,
          position: newPosition,
        ),
      );
    }
  }

  @override
  spawnFor(Connection connection) {
    if (this.world == null) throw Exception("No world to spawn in!");
    if (this.worldId == null) throw Exception("No world id to spawn in!");
    var packet = connection.protocol!
        .assertPacket<SendablePacket<SpawnPlayerPacketData>>(
          PacketIds.spawnPlayer,
        );
    packet.send(
      connection,
      SpawnPlayerPacketData(
        playerId: this.worldId!,
        name: name,
        position: position,
      ),
    );
  }

  @override
  destroy({byPlayer = false}) {
    if (!byPlayer) logger.warning("Warning: Destroying player entity $name");
    return super.destroy();
  }
}

import 'entity.dart';
import 'networking/connection.dart';
import 'networking/packet.dart';
import 'networking/protocol.dart';
import 'protocols/7/packetdata.dart';
import 'registries/namedregistry.dart';
import 'registries/serviceregistry.dart';
import 'world.dart';

class Player implements Nameable<String> {
  String name;
  String fancyName;
  Connection? connection;
  ServiceRegistry? serviceRegistry;
  Entity? entity;
  String get id => name;
  World? world;

  Player({
    required this.name,
    required this.fancyName,
    this.connection,
    this.serviceRegistry,
    defaultEntity = true,
    entity,
  }) : assert(
         (entity == null) || (entity != null && defaultEntity == false),
         'Cannot set entity and defaultEntity at the same time',
       ) {
    if (defaultEntity) {
      entity = Entity(name: name, fancyName: fancyName);
    }
    this.entity = entity;
  }

  void loadWorld(World world) async {
    if (connection?.protocol != null) {
      var packets = await connection!.protocol!.packets;
      var levelInitPacket =
          packets[PacketIds.levelInitialize]
              as SendablePacket<LevelInitializePacketData>;
      levelInitPacket.send(connection!, LevelInitializePacketData());
    }
    this.world = world;
  }
}

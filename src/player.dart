import 'block.dart';
import 'datatypes.dart';
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
    bool defaultEntity = true,
    Entity? entity,
  }) : assert(
         (entity == null) || (defaultEntity == false),
         'Cannot set entity and defaultEntity at the same time',
       ) {
    if (defaultEntity) {
      entity = Entity(name: name, fancyName: fancyName);
    }
    this.entity = entity;
  }

  void identify() {
    if (connection == null) {
      return;
    }
    SendablePacket<IdentificationPacketData>? identificationPacket =
        connection!.protocol?.packets[PacketIds.identification]
            as SendablePacket<IdentificationPacketData>?;
    if (identificationPacket == null) {
      throw Exception('Packet not found for ID: ${PacketIds.identification}');
    }
    // TODO: Use proper values here
    identificationPacket.send(
      connection!,
      IdentificationPacketData(
        protocolVersion: connection!.protocol!.version,
        name: "Target-Classic",
        keyOrMotd: "Gotta unhardcode this",
        userType: 0,
      ),
    );
  }

  void loadWorld(World world) async {
    if (connection?.protocol != null) {
      var packets = await connection!.protocol!.packets;
      var levelInitPacket =
          packets[PacketIds.levelInitialize]
              as SendablePacket<LevelInitializePacketData>;
      levelInitPacket.send(connection!, LevelInitializePacketData());
      for (LevelDataChunkPacketData chunk in world.getNetworkChunks()) {
        var levelDataChunkPacket =
            packets[PacketIds.levelDataChunk]
                as SendablePacket<LevelDataChunkPacketData>;
        levelDataChunkPacket.send(connection!, chunk);
        await Future.delayed(const Duration(milliseconds: 5));
      }
      var levelFinalizePacket =
          packets[PacketIds.levelFinalize]
              as SendablePacket<LevelFinalizePacketData>;
      levelFinalizePacket.send(
        connection!,
        LevelFinalizePacketData(
          sizeX: world.size.x,
          sizeY: world.size.y,
          sizeZ: world.size.z,
        ),
      );
      world.emitter.on('setBlock', (
        ({Vector3I position, BlockID block}) blockData,
      ) {
        SendablePacket<SetBlockServerPacketData>? setBlockPacket =
            connection!.protocol?.packets[PacketIds.setBlockServer]
                as SendablePacket<SetBlockServerPacketData>?;
        if (setBlockPacket == null) {
          print("Packet not found for ID: ${PacketIds.setBlockServer}");
          return;
        }
        Vector3I position = blockData.position;
        BlockID block = blockData.block;
        setBlockPacket.send(
          connection!,
          SetBlockServerPacketData(
            x: position.x,
            y: position.y,
            z: position.z,
            blockId: block.index,
          ),
        );
      });
    }
    this.world = world;
  }
}

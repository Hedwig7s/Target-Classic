import 'package:events_emitter/events_emitter.dart';

import 'block.dart';
import 'datatypes.dart';
import 'entity.dart';
import 'networking/connection.dart';
import 'networking/packet.dart';
import 'networking/protocol.dart';
import 'networking/protocols/7/packetdata.dart';
import 'playerentity.dart';
import 'registries/namedregistry.dart';
import 'registries/serviceregistry.dart';
import 'world.dart';

class PlayerListenedEvents {
  EventListener? entityAdded;
  EventListener? setBlock;
}

class Player implements Nameable<String> {
  final String name;
  String fancyName;
  Connection? connection;
  ServiceRegistry? serviceRegistry;
  PlayerEntity? entity;
  String get id => name;
  World? world;
  final EventEmitter emitter = EventEmitter();
  PlayerListenedEvents listenedEvents = PlayerListenedEvents();

  Player({
    required this.name,
    required this.fancyName,
    this.connection,
    this.serviceRegistry,
  }) {
    this.entity = PlayerEntity(name: name, fancyName: fancyName, player: this);
  }

  void identify() {
    if (connection == null) {
      return;
    }
    if (connection!.protocol == null)
      throw Exception("Attempt to identify without protocol");
    var identificationPacket = connection!.protocol!
        .assertPacket<SendablePacket<IdentificationPacketData>>(
          PacketIds.identification,
        );

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
    emitter.emit("identified", this);
  }

  void spawn() {
    if (this.world == null) throw Exception("No world to spawn in!");
    this.entity?.spawn(this.world!, calledBack: true);
    if (this.connection?.protocol != null && this.entity != null) {
      var packet = this.connection!.protocol!
          .assertPacket<SendablePacket<SpawnPlayerPacketData>>(
            PacketIds.spawnPlayer,
          );
      print("Spawning player ${entity!.name} with id ${entity!.worldId}");
      packet.send(
        connection!,
        SpawnPlayerPacketData(
          playerId: -1,
          name: name,
          position: entity!.position,
        ),
      );
      // TODO: Spawn other players
    }
  }

  Future<void> loadWorld(World world) async {
    listenedEvents.setBlock?.cancel();
    listenedEvents.entityAdded?.cancel();

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
      EventCallback<({Vector3I position, BlockID block})> onSetBlock = (
        ({Vector3I position, BlockID block}) blockData,
      ) {
        var setBlockPacket = connection!.protocol
            ?.getPacket<SendablePacket<SetBlockServerPacketData>>(
              PacketIds.setBlockServer,
            );
        if (setBlockPacket == null) {
          print("Packet ${PacketIds.setBlockServer} not found");
          return;
        }
        Vector3I position = blockData.position;
        BlockID block = blockData.block;
        setBlockPacket.send(
          connection!,
          SetBlockServerPacketData(position: position, blockId: block.index),
        );
      };
      listenedEvents.setBlock = world.emitter
          .on<({Vector3I position, BlockID block})>('setBlock', onSetBlock);
      EventCallback<Entity> onEntityAdded = (Entity entity) {};
      listenedEvents.entityAdded = world.emitter.on<Entity>(
        "entityAdded",
        onEntityAdded,
      );
    }
    this.world = world;
    emitter.emit("worldLoaded", world);
  }
}

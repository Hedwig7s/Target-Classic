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
import 'utility/clearemitter.dart';
import 'world.dart';

class PlayerListenedWorldEvents {
  EventListener? entityAdded;
  EventListener? entityRemoved;
  EventListener? setBlock;
  Map<Entity, EventListener> entityMovedListeners = {};
  clear() {
    entityAdded?.cancel();
    entityRemoved?.cancel();
    setBlock?.cancel();
    for (var listener in entityMovedListeners.values) {
      listener.cancel();
    }
    entityMovedListeners.clear();
  }
}

class Player implements Nameable<String> {
  final String name;
  String fancyName;
  Connection? connection;
  ServiceRegistry? serviceRegistry;
  PlayerEntity? entity;
  World? world;
  bool destroyed = false;
  final EventEmitter emitter = EventEmitter();
  PlayerListenedWorldEvents worldEvents = PlayerListenedWorldEvents();

  Player({
    required this.name,
    required this.fancyName,
    this.connection,
    this.serviceRegistry,
  }) {
    this.entity = PlayerEntity(name: name, fancyName: fancyName, player: this);
    this.connection?.emitter.on("closed", (data) {
      this.destroy();
    });
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
    emitter.emit("identified");
  }

  void spawn() {
    if (this.world == null) throw Exception("No world to spawn in!");
    this.entity?.spawn(this.world!, calledBack: true);
    if (this.connection?.protocol != null && this.entity != null) {
      var packet = this.connection!.protocol!
          .assertPacket<SendablePacket<SpawnPlayerPacketData>>(
            PacketIds.spawnPlayer,
          );
      packet.send(
        connection!,
        SpawnPlayerPacketData(
          playerId: -1,
          name: name,
          position: entity!.position,
        ),
      );
    }
    emitter.emit("spawned");
  }

  Future<void> loadWorld(World world) async {
    worldEvents.clear();
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
      EventCallback<Entity> onEntityAdded = (Entity entity) {
        if (entity == this.entity) return;
        entity.spawnFor(connection!);
        var setPositionPacket = connection!.protocol
            ?.getPacket<SendablePacket<SetPositionAndOrientationPacketData>>(
              PacketIds.setPositionAndOrientation,
            );
        if (setPositionPacket == null) {
          print("Packet ${PacketIds.setPositionAndOrientation} not found");
          return;
        }
        entity.emitter.on<EntityPosition>("moved", (EntityPosition position) {
          setPositionPacket.send(
            connection!,
            SetPositionAndOrientationPacketData(
              playerId: entity.worldId!,
              position: position,
            ),
          );
        });
      };
      EventCallback<Entity> onEntityRemoved = (Entity entity) {
        if (entity == this.entity) return;
        worldEvents.entityMovedListeners[entity]?.cancel();
        worldEvents.entityMovedListeners.remove(entity);
        // TODO: Send despawn packet
      };
      for (var entity in world.entities.values) {
        onEntityAdded.call(entity);
      }
      worldEvents.entityAdded = world.emitter.on<Entity>(
        "entityAdded",
        onEntityAdded,
      );
      worldEvents.entityRemoved = world.emitter.on<Entity>(
        "entityRemoved",
        onEntityRemoved,
      );
      worldEvents.setBlock = world.emitter
          .on<({Vector3I position, BlockID block})>('setBlock', onSetBlock);
    }
    this.world = world;
    emitter.emit("worldLoaded", world);
  }

  void destroy() {
    emitter.emit('destroyed');
    clearEmitter(emitter);
    this.worldEvents.setBlock?.cancel();
    this.worldEvents.entityAdded?.cancel();
    this.worldEvents.entityRemoved?.cancel();
    worldEvents.entityMovedListeners.clear();

    for (var listener in worldEvents.entityMovedListeners.values) {
      listener.cancel();
    }
    this.destroyed = true;
    this.entity?.destroy(byPlayer: true);
  }
}

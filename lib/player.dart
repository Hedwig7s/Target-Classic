import 'package:events_emitter/events_emitter.dart';
import 'package:logging/logging.dart';
import 'config/serverconfig.dart';

import 'block.dart';
import 'datatypes.dart';
import 'entity.dart';
import 'networking/connection.dart';
import 'networking/packet.dart';
import 'networking/protocol.dart';
import 'networking/packetdata.dart';
import 'playerentity.dart';
import 'registries/namedregistry.dart';
import 'registries/instanceregistry.dart';
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
  InstanceRegistry? instanceRegistry;
  PlayerEntity? entity;
  World? world;
  bool destroyed = false;
  final EventEmitter emitter = EventEmitter();
  final PlayerListenedWorldEvents worldEvents = PlayerListenedWorldEvents();
  final Logger logger;

  Player({
    required this.name,
    required this.fancyName,
    this.instanceRegistry,
    this.connection,
  }) : logger = Logger("Player $name") {
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
    String serverName = "Name not set", motd = "Motd not set";
    ServerConfig? config = instanceRegistry?.tryGetInstance<ServerConfig>(
      "serverconfig",
    );
    if (config != null) {
      serverName = config.serverName;
      motd = config.motd;
    } else
      logger.warning(
        "Warning: No server config found for player $name. Name and motd not set",
      );

    identificationPacket.send(
      connection!,
      IdentificationPacketData(
        protocolVersion: connection!.protocol!.version,
        name: serverName,
        keyOrMotd: motd,
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
    logger.info("Loading world ${world.name}");
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
          logger.warning("Packet ${PacketIds.setBlockServer} not found");
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

        var serverConfig = instanceRegistry?.tryGetInstance<ServerConfig>(
          "serverconfig",
        );
        bool useRelativeMovements = serverConfig?.useRelativeMovements ?? false;

        var setPositionPacket = connection!.protocol
            ?.getPacket<SendablePacket<SetPositionAndOrientationPacketData>>(
              PacketIds.setPositionAndOrientation,
            );

        if (setPositionPacket == null) {
          logger.warning(
            "Packet ${PacketIds.setPositionAndOrientation} not found",
          );
          return;
        }

        void sendFullPositionUpdate(EntityPosition position) {
          setPositionPacket.send(
            connection!,
            SetPositionAndOrientationPacketData(
              playerId: entity.worldId!,
              position: position,
            ),
          );
        }

        EventCallback<EntityPosition> onMoved;

        if (useRelativeMovements) {
          var posAndRotUpdatePacket = connection!.protocol?.getPacket<
            SendablePacket<PositionAndOrientationUpdatePacketData>
          >(PacketIds.positionAndOrientationUpdate);
          var positionUpdatePacket = connection!.protocol
              ?.getPacket<SendablePacket<PositionUpdatePacketData>>(
                PacketIds.positionUpdate,
              );
          var orientationUpdatePacket = connection!.protocol
              ?.getPacket<SendablePacket<OrientationUpdatePacketData>>(
                PacketIds.orientationUpdate,
              );

          if (posAndRotUpdatePacket != null &&
              orientationUpdatePacket != null &&
              positionUpdatePacket != null) {
            EntityPosition? previous;
            int updatesSinceFullSync = 0;
            const int FULL_SYNC_INTERVAL = 50;

            onMoved = (EntityPosition position) {
              if (previous == null ||
                  updatesSinceFullSync >= FULL_SYNC_INTERVAL) {
                sendFullPositionUpdate(position);
                previous = position;
                updatesSinceFullSync = 0;
                return;
              }

              EntityPosition change = position - previous!;

              if (change.vector == Vector3F(0, 0, 0) &&
                  change.yaw == previous!.yaw &&
                  change.pitch == previous!.pitch)
                return;

              if (change.x.abs() >= 3.9 ||
                  change.y.abs() >= 3.9 ||
                  change.z.abs() >= 3.9) {
                sendFullPositionUpdate(position);
                previous = position;
                updatesSinceFullSync = 0;
                return;
              }

              if (position.vector == previous!.vector) {
                orientationUpdatePacket.send(
                  connection!,
                  OrientationUpdatePacketData(
                    playerId: entity.worldId!,
                    position: change,
                  ),
                );
              } else if (position.yaw == previous!.yaw &&
                  position.pitch == previous!.pitch) {
                positionUpdatePacket.send(
                  connection!,
                  PositionUpdatePacketData(
                    playerId: entity.worldId!,
                    position: change.vector,
                  ),
                );
              } else {
                posAndRotUpdatePacket.send(
                  connection!,
                  PositionAndOrientationUpdatePacketData(
                    playerId: entity.worldId!,
                    position: change,
                  ),
                );
              }

              previous = position;
              updatesSinceFullSync++;
            };
          } else {
            onMoved = sendFullPositionUpdate;
          }
        } else {
          onMoved = sendFullPositionUpdate;
        }

        worldEvents.entityMovedListeners[entity] = entity.emitter
            .on<EntityPosition>("moved", onMoved);
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
    logger.fine("Destroying player $name");
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

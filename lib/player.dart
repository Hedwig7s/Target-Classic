import 'package:events_emitter/events_emitter.dart';
import 'package:logging/logging.dart';
import 'package:target_classic/context.dart';
import 'package:target_classic/chat/chatroom.dart';
import 'package:target_classic/config/serverconfig.dart';

import 'package:target_classic/block.dart';
import 'package:target_classic/cooldown.dart';
import 'package:target_classic/datatypes.dart';
import 'package:target_classic/entity.dart';
import 'package:target_classic/chat/message.dart';
import 'package:target_classic/networking/connection.dart';
import 'package:target_classic/networking/packet.dart';
import 'package:target_classic/networking/protocol.dart';
import 'package:target_classic/networking/packetdata.dart';
import 'package:target_classic/playerentity.dart';
import 'package:target_classic/registries/namedregistry.dart';
import 'package:target_classic/utility/clearemitter.dart';
import 'package:target_classic/world.dart';

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

class PlayerCooldowns {
  final Cooldown setBlock;
  final Cooldown move;
  PlayerCooldowns({Cooldown? setBlock, Cooldown? move, Cooldown? chat})
    : setBlock =
          setBlock ??
          Cooldown(maxCount: 20, resetTime: const Duration(seconds: 1)),
      move =
          move ?? Cooldown(maxCount: 30, resetTime: const Duration(seconds: 1));
}

class Player implements Nameable<String> {
  final String name;
  String fancyName;
  Connection? connection;
  ServerContext? context;
  PlayerEntity? entity;
  Chatroom? chatroom;
  World? world;
  bool destroyed = false;
  final EventEmitter emitter = EventEmitter();
  final PlayerListenedWorldEvents worldEvents = PlayerListenedWorldEvents();
  final Logger logger;
  final PlayerCooldowns cooldowns;

  Player({
    required this.name,
    required this.fancyName,
    this.context,
    this.connection,
    PlayerCooldowns? cooldowns,
  }) : assert(name.isNotEmpty, "Name must not be empty"),
       logger = Logger("Player $name"),
       cooldowns = cooldowns ?? PlayerCooldowns() {
    this.entity = PlayerEntity(
      name: name,
      fancyName: fancyName,
      player: this,
      context: context,
    );
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
    ServerConfig? config = context?.serverConfig;
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

        var serverConfig = context?.serverConfig;
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
      EventCallback<(Entity, int)> onEntityRemoved = (
        (Entity entity, int worldId) data,
      ) {
        Entity entity = data.$1;
        int worldId = data.$2;
        if (entity == this.entity) return;
        worldEvents.entityMovedListeners[entity]?.cancel();
        worldEvents.entityMovedListeners.remove(entity);
        var despawnPacket = connection!.protocol
            ?.getPacket<SendablePacket<DespawnPlayerPacketData>>(
              PacketIds.despawnPlayer,
            );
        if (despawnPacket == null) {
          logger.warning("Packet ${PacketIds.despawnPlayer} not found");
          return;
        }
        despawnPacket.send(
          connection!,
          DespawnPlayerPacketData(playerId: worldId),
        );
      };
      for (var entity in world.entities.values) {
        onEntityAdded.call(entity);
      }
      worldEvents.entityAdded = world.emitter.on<Entity>(
        "entityAdded",
        onEntityAdded,
      );
      worldEvents.entityRemoved = world.emitter.on<(Entity, int)>(
        "entityRemoved",
        onEntityRemoved,
      );
      worldEvents.setBlock = world.emitter
          .on<({Vector3I position, BlockID block})>('setBlock', onSetBlock);
    }
    this.world = world;
    emitter.emit("worldLoaded", world);
  }

  void setBlock(Vector3I blockPos, BlockID blockId) {
    if (world == null) return;
    if (!cooldowns.setBlock.canUse()) {
      connection?.protocol
          ?.getPacket<SendablePacket<SetBlockServerPacketData>>(
            PacketIds.setBlockServer,
          )
          ?.send(
            connection!,
            SetBlockServerPacketData(
              position: blockPos,
              blockId: world!.getBlock(blockPos),
            ),
          );
      return;
    }
    world?.setBlock(blockPos, blockId);
  }

  void disconnect(String reason) {
    if (connection?.closed ?? false) return;
    logger.info("Disconnecting player $name");
    if (!connection!.closed) {
      connection!.close(reason);
    }
    emitter.emit('disconnected');
  }

  void destroy() {
    logger.fine("Destroying player $name");
    this.entity?.despawn();
    emitter.emit('destroyed');
    clearEmitter(emitter);
    this.connection?.close("Player destroyed");
    this.worldEvents.clear();

    for (var listener in worldEvents.entityMovedListeners.values) {
      listener.cancel();
    }
    this.destroyed = true;
    this.entity?.destroy(byPlayer: true);
  }

  void move(EntityPosition newPosition, {bool teleport = true}) {
    if (this.entity == null) return;
    if (!teleport && !cooldowns.move.canUse()) {
      connection?.protocol
          ?.getPacket<SendablePacket<SetPositionAndOrientationPacketData>>(
            PacketIds.setPositionAndOrientation,
          )
          ?.send(
            connection!,
            SetPositionAndOrientationPacketData(
              playerId: -1,
              position: entity!.position,
            ),
          );
      return;
    }
    this.entity?.move(newPosition, byPlayer: !teleport);
  }

  void chat(Message message) {
    this.chatroom?.sendMessage(this, message);
  }

  void sendMessage(Message message, [String overflowPrefix = "> "]) {
    if (connection == null || connection!.closed) return;

    var chatPacket = connection!.protocol!
        .assertPacket<SendablePacket<MessagePacketData>>(PacketIds.message);

    for (String part in message.getParts(overflowPrefix: overflowPrefix)) {
      chatPacket.send(
        connection!,
        MessagePacketData(message: part, playerId: 0),
      );
    }
  }
}

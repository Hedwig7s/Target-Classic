import 'package:target_classic/colorcodes.dart';
import 'package:target_classic/config/serverconfig.dart';
import 'package:target_classic/context.dart';
import 'package:target_classic/message.dart';

import 'package:target_classic/networking/protocol.dart';

import 'package:target_classic/block.dart';
import 'package:target_classic/datatypes.dart';
import 'package:target_classic/networking/connection.dart';
import 'package:target_classic/networking/packet.dart';
import 'package:target_classic/player.dart';
import 'package:target_classic/world.dart';
import 'package:target_classic/networking/packetdata.dart';
import 'dart:convert';
import 'package:target_classic/dataparser/builder.dart';
import 'package:target_classic/dataparser/parser.dart';

class IdentificationPacket7 extends Packet
    with
        SendablePacket<IdentificationPacketData>,
        ReceivablePacket<IdentificationPacketData> {
  static final DataParser parser =
      DataParserBuilder()
          .bigEndian()
          .uint8()
          .uint8()
          .fixedString(64, Encoding.getByName('ascii')!, padding: ' ')
          .fixedString(64, Encoding.getByName('ascii')!, padding: ' ')
          .uint8()
          .build();

  int id = 0x00;
  int length = 131;

  IdentificationPacketData decode(List<int> data) {
    var decodedData = parser.decode(data);
    return IdentificationPacketData(
      id: decodedData[0],
      protocolVersion: decodedData[1],
      name: decodedData[2],
      keyOrMotd: decodedData[3],
      userType: decodedData[4],
    );
  }

  @override
  List<int> encode(IdentificationPacketData data) {
    return parser.encode([
      data.id,
      data.protocolVersion,
      data.name,
      data.keyOrMotd,
      data.userType,
    ]);
  }

  @override
  Future<void> receive(Connection connection, List<int> data) async {
    ServerContext? context = connection.context;
    ServerConfig? serverConfig = context?.serverConfig;
    IdentificationPacketData decodedData = decode(data);
    if (decodedData.name
        .replaceAllMapped(RegExp('[\x00-\x1F\x7F-\xFF]'), (match) => '')
        .isEmpty) {
      connection.logger.warning("Invalid player name: ${decodedData.name}");
      connection.close("Invalid player name");
      return;
    }
    if ((serverConfig?.verifyNames ?? false) &&
        context?.saltManager != null &&
        !context!.saltManager!.verifyName(
          decodedData.name,
          decodedData.keyOrMotd,
        )) {
      connection.logger.warning("Invalid mppass");
      connection.close("Invalid mppass");
      return;
    }
    PlayerRegistry? playerRegistry = context?.playerRegistry;
    if (playerRegistry == null) {
      connection.logger.warning("No player registry found!");
    }
    if (playerRegistry?.toMap().containsKey(decodedData.name) ?? false) {
      connection.logger.warning(
        "Player name already taken: ${decodedData.name}",
      );
      connection.close("Player name already taken");
      return;
    }

    if (serverConfig == null) {
      connection.logger.warning(
        "No config found during identification. May result in unintended behaviour",
      );
    }

    if (context?.serverConfig?.maxPlayers != null &&
        playerRegistry != null &&
        playerRegistry.length >= context!.serverConfig!.maxPlayers) {
      connection.logger.warning(
        "Server is full, cannot identify player ${decodedData.name}",
      );
      connection.close("Server is full");
      return;
    }

    Player player = Player(
      name: decodedData.name,
      fancyName: decodedData.name,
      connection: connection,
      context: connection.context,
    );
    connection.player = player;
    playerRegistry?.register(player);
    if (player.entity != null)
      context?.entityRegistry?.register(player.entity!);
    connection.logger.info(
      "Connection from ${connection.socket.remoteAddress.address}:${connection.socket.remotePort} identified as ${decodedData.name}",
    );
    try {
      player.identify();
    } catch (e, stackTrace) {
      connection.logger.warning("Error identifying player: $e\n$stackTrace");
      connection.close("Error occurred during identification");
      return;
    }
    World? world = context?.worldRegistry?.defaultWorld;
    if (world != null) {
      await player.loadWorld(world);
      player.spawn();
    } else {
      connection.logger.severe(
        'No default world found for player ${player.name}',
      );
    }
  }
}

class PingPacket7 extends Packet
    with SendablePacket<PingPacketData>, ReceivablePacket {
  static final DataParser parser =
      DataParserBuilder().bigEndian().uint8().build();

  int id = 0x01; // Fixed to match packetdata ID
  int length = 1;

  PingPacketData decode(List<int> data) {
    return PingPacketData();
  }

  @override
  List<int> encode(PingPacketData data) {
    return parser.encode([data.id]);
  }

  @override
  Future<void> receive(Connection connection, List<int> data) async {
    // Do nothing
    // This packet is just a ping, no data to process
  }
}

class LevelInitializePacket7 extends Packet
    with SendablePacket<LevelInitializePacketData> {
  static final DataParser parser =
      DataParserBuilder().bigEndian().uint8().build();

  int id = 0x02;
  int length = 1;

  LevelInitializePacketData decode(List<int> data) {
    return LevelInitializePacketData();
  }

  @override
  List<int> encode(LevelInitializePacketData data) {
    return parser.encode([data.id]);
  }
}

class LevelDataChunkPacket7 extends Packet
    with SendablePacket<LevelDataChunkPacketData> {
  static final DataParser parser =
      DataParserBuilder()
          .bigEndian()
          .uint8()
          .uint16()
          .bytes(1024)
          .uint8()
          .build();

  int id = 0x03;
  int length = 1028;

  LevelDataChunkPacketData decode(List<int> data) {
    var decodedData = parser.decode(data);
    return LevelDataChunkPacketData(
      chunkLength: decodedData[1],
      chunkData: decodedData[2],
      percentComplete: decodedData[3],
    );
  }

  @override
  List<int> encode(LevelDataChunkPacketData data) {
    return parser.encode([
      data.id,
      data.chunkLength,
      data.chunkData,
      data.percentComplete,
    ]);
  }
}

class LevelFinalizePacket7 extends Packet
    with SendablePacket<LevelFinalizePacketData> {
  static final DataParser parser =
      DataParserBuilder()
          .bigEndian()
          .uint8()
          .uint16()
          .uint16()
          .uint16()
          .build();

  int id = 0x04;
  int length = 7;

  LevelFinalizePacketData decode(List<int> data) {
    var decodedData = parser.decode(data);
    return LevelFinalizePacketData(
      sizeX: decodedData[1],
      sizeY: decodedData[2],
      sizeZ: decodedData[3],
    );
  }

  @override
  List<int> encode(LevelFinalizePacketData data) {
    return parser.encode([data.id, data.sizeX, data.sizeY, data.sizeZ]);
  }
}

class SetBlockClientPacket7 extends Packet
    with ReceivablePacket<SetBlockClientPacketData> {
  static final DataParser parser =
      DataParserBuilder()
          .bigEndian()
          .uint8()
          .uint16()
          .uint16()
          .uint16()
          .uint8()
          .uint8()
          .build();
  int id = 0x05;
  int length = 9;
  SetBlockClientPacketData decode(List<int> data) {
    var decodedData = parser.decode(data);
    return SetBlockClientPacketData(
      position: Vector3I(decodedData[1], decodedData[2], decodedData[3]),
      mode: decodedData[4],
      blockId: decodedData[5],
    );
  }

  List<int> encode(SetBlockClientPacketData data) {
    return parser.encode([
      data.id,
      data.position.x,
      data.position.y,
      data.position.z,
      data.blockId,
      data.mode,
    ]);
  }

  @override
  Future<void> receive(Connection connection, List<int> data) async {
    if (connection.player?.world == null) return;
    var decodedData = decode(data);
    if (decodedData.mode != 0 && decodedData.mode != 1) {
      connection.logger.warning("Invalid mode: ${decodedData.mode}");
      return;
    }
    if (decodedData.blockId >= BlockID.values.length) {
      connection.logger.warning("Invalid block ID: ${decodedData.blockId}");
      return;
    }
    Vector3I blockPos = Vector3I(
      decodedData.position.x,
      decodedData.position.y,
      decodedData.position.z,
    );

    connection.player!.setBlock(
      blockPos,
      decodedData.mode == 0 ? BlockID.air : BlockID.values[decodedData.blockId],
    );
  }
}

class SetBlockServerPacket7 extends Packet
    with SendablePacket<SetBlockServerPacketData> {
  static final DataParser parser =
      DataParserBuilder()
          .bigEndian()
          .uint8()
          .uint16()
          .uint16()
          .uint16()
          .uint8()
          .build();

  int id = 0x06;
  int length = 7;

  SetBlockServerPacketData decode(List<int> data) {
    var decodedData = parser.decode(data);
    return SetBlockServerPacketData(
      position: Vector3I(decodedData[1], decodedData[2], decodedData[3]),
      blockId: decodedData[4],
    );
  }

  @override
  List<int> encode(SetBlockServerPacketData data) {
    return parser.encode([
      data.id,
      data.position.x,
      data.position.y,
      data.position.z,
      data.blockId,
    ]);
  }
}

class SpawnPlayerPacket7 extends Packet
    with SendablePacket<SpawnPlayerPacketData> {
  static final DataParser parser =
      DataParserBuilder()
          .bigEndian()
          .uint8()
          .sint8()
          .fixedString(64, Encoding.getByName('ascii')!, padding: ' ')
          .fixedPoint(size: 2, fractionalBits: 5, signed: true)
          .fixedPoint(size: 2, fractionalBits: 5, signed: true)
          .fixedPoint(size: 2, fractionalBits: 5, signed: true)
          .uint8()
          .uint8()
          .build();
  int id = 0x07;
  int length = 74;
  SpawnPlayerPacketData decode(List<int> data) {
    var decodedData = parser.decode(data);
    return SpawnPlayerPacketData(
      playerId: decodedData[1],
      name: decodedData[2],
      position: EntityPosition(
        decodedData[3],
        decodedData[4],
        decodedData[5],
        decodedData[6],
        decodedData[7],
      ),
    );
  }

  @override
  List<int> encode(SpawnPlayerPacketData data) {
    return parser.encode([
      data.id,
      data.playerId,
      data.name,
      data.position.x,
      data.position.y,
      data.position.z,
      data.position.yaw,
      data.position.pitch,
    ]);
  }
}

class SetPositionAndOrientationPacket7 extends Packet
    with
        SendablePacket<SetPositionAndOrientationPacketData>,
        ReceivablePacket<SetPositionAndOrientationPacketData> {
  static final DataParser parser =
      DataParserBuilder()
          .bigEndian()
          .uint8()
          .sint8()
          .fixedPoint(size: 2, fractionalBits: 5, signed: true)
          .fixedPoint(size: 2, fractionalBits: 5, signed: true)
          .fixedPoint(size: 2, fractionalBits: 5, signed: true)
          .uint8()
          .uint8()
          .build();
  int id = 0x08;
  int length = 10;
  SetPositionAndOrientationPacketData decode(List<int> data) {
    var decodedData = parser.decode(data);
    return SetPositionAndOrientationPacketData(
      playerId: decodedData[1],
      position: EntityPosition(
        decodedData[2],
        decodedData[3],
        decodedData[4],
        decodedData[5],
        decodedData[6],
      ),
    );
  }

  @override
  List<int> encode(SetPositionAndOrientationPacketData data) {
    return parser.encode([
      data.id,
      data.playerId,
      data.position.x,
      data.position.y,
      data.position.z,
      data.position.yaw,
      data.position.pitch,
    ]);
  }

  @override
  Future<void> receive(Connection connection, List<int> data) async {
    var decodedData = decode(data);
    if (connection.player == null) return;
    connection.player!.entity?.move(decodedData.position, byPlayer: true);
  }
}

class PositionAndOrientationUpdatePacket7 extends Packet
    with SendablePacket<PositionAndOrientationUpdatePacketData> {
  static final DataParser parser =
      DataParserBuilder()
          .bigEndian()
          .uint8()
          .sint8()
          .fixedPoint(size: 1, fractionalBits: 5, signed: true)
          .fixedPoint(size: 1, fractionalBits: 5, signed: true)
          .fixedPoint(size: 1, fractionalBits: 5, signed: true)
          .uint8()
          .uint8()
          .build();
  int id = 0x09;
  int length = 10;
  PositionAndOrientationUpdatePacketData decode(List<int> data) {
    var decodedData = parser.decode(data);
    return PositionAndOrientationUpdatePacketData(
      playerId: decodedData[1],
      position: EntityPosition(
        decodedData[2],
        decodedData[3],
        decodedData[4],
        decodedData[5],
        decodedData[6],
      ),
    );
  }

  @override
  List<int> encode(PositionAndOrientationUpdatePacketData data) {
    return parser.encode([
      data.id,
      data.playerId,
      data.position.x,
      data.position.y,
      data.position.z,
      data.position.yaw,
      data.position.pitch,
    ]);
  }
}

class PositionUpdatePacket7 extends Packet
    with SendablePacket<PositionUpdatePacketData> {
  static final DataParser parser =
      DataParserBuilder()
          .bigEndian()
          .uint8()
          .sint8()
          .fixedPoint(size: 1, fractionalBits: 5, signed: true)
          .fixedPoint(size: 1, fractionalBits: 5, signed: true)
          .fixedPoint(size: 1, fractionalBits: 5, signed: true)
          .build();
  int id = 0x09;
  int length = 10;
  PositionUpdatePacketData decode(List<int> data) {
    var decodedData = parser.decode(data);
    return PositionUpdatePacketData(
      playerId: decodedData[1],
      position: Vector3F(decodedData[2], decodedData[3], decodedData[4]),
    );
  }

  @override
  List<int> encode(PositionUpdatePacketData data) {
    return parser.encode([
      data.id,
      data.playerId,
      data.position.x,
      data.position.y,
      data.position.z,
    ]);
  }
}

class OrientationUpdatePacket7 extends Packet
    with SendablePacket<OrientationUpdatePacketData> {
  static final DataParser parser =
      DataParserBuilder().bigEndian().uint8().sint8().uint8().uint8().build();
  int id = 0x09;
  int length = 10;
  OrientationUpdatePacketData decode(List<int> data) {
    var decodedData = parser.decode(data);
    return OrientationUpdatePacketData(
      playerId: decodedData[1],
      position: EntityPosition(0, 0, 0, decodedData[2], decodedData[3]),
    );
  }

  @override
  List<int> encode(OrientationUpdatePacketData data) {
    return parser.encode([
      data.id,
      data.playerId,
      data.position.yaw,
      data.position.pitch,
    ]);
  }
}

class DespawnPlayerPacket7 extends Packet
    with SendablePacket<DespawnPlayerPacketData> {
  static final DataParser parser =
      DataParserBuilder().bigEndian().uint8().sint8().build();
  int id = 0x0A;
  int length = 2;

  DespawnPlayerPacketData decode(List<int> data) {
    var decodedData = parser.decode(data);
    return DespawnPlayerPacketData(playerId: decodedData[1]);
  }

  @override
  List<int> encode(DespawnPlayerPacketData data) {
    return parser.encode([data.id, data.playerId]);
  }
}

class MessagePacket7 extends Packet
    with
        SendablePacket<MessagePacketData>,
        ReceivablePacket<MessagePacketData> {
  static final DataParser parser =
      DataParserBuilder()
          .bigEndian()
          .uint8()
          .sint8()
          .fixedString(64, Encoding.getByName('ascii')!, padding: ' ')
          .build();
  int id = 0x0B;
  int length = 66;

  MessagePacketData decode(List<int> data) {
    var decodedData = parser.decode(data);
    return MessagePacketData(playerId: decodedData[1], message: decodedData[2]);
  }

  @override
  List<int> encode(MessagePacketData data) {
    return parser.encode([data.id, data.playerId, data.message]);
  }

  @override
  Future<void> receive(Connection connection, List<int> data) async {
    var decodedData = decode(data);
    if (connection.player == null) return;
    Player player = connection.player!;
    String message = decodedData.message.trim();
    message = message.replaceAllMapped(RegExp("%([0-9a-fA-F])"), (match) {
      // Damn you classicube
      String colorCode = match.group(1) ?? "";
      if (colorCode.isEmpty) {
        return match.group(0) ?? "";
      }
      return "&$colorCode";
    });
    if (message.isEmpty) return;
    if (player.chatroom != null) {
      try {
        player.chat(Message(message));
      } catch (e) {
        connection.logger.warning("Error sending message in chatroom: $e");
        connection.protocol
            ?.getPacket<SendablePacket<MessagePacketData>>(PacketIds.message)
            ?.send(
              connection,
              MessagePacketData(
                playerId: 0,
                message: "${ColorCodes.red}Error sending message",
              ),
            );
      }
    } else {
      connection.protocol
          ?.getPacket<SendablePacket<MessagePacketData>>(PacketIds.message)
          ?.send(
            connection,
            MessagePacketData(
              playerId: 0,
              message: "${ColorCodes.red}Not in a chatroom!",
            ),
          );
    }
  }
}

class DisconnectPlayerPacket7 extends Packet
    with SendablePacket<DisconnectPlayerPacketData> {
  static final DataParser parser =
      DataParserBuilder()
          .bigEndian()
          .uint8()
          .fixedString(64, Encoding.getByName("ascii")!, padding: ' ')
          .build();
  int id = 0x0C;
  int length = 2;

  DisconnectPlayerPacketData decode(List<int> data) {
    var decodedData = parser.decode(data);
    return DisconnectPlayerPacketData(reason: decodedData[1]);
  }

  @override
  List<int> encode(DisconnectPlayerPacketData data) {
    return parser.encode([data.id, data.reason]);
  }

  @override
  void send(Connection connection, DisconnectPlayerPacketData data) {
    if (connection.socketClosed) return;
    var encodedData = encode(data);
    connection.write(encodedData, force: true);
  }
}

class UpdateUserTypePacket7 extends Packet
    with SendablePacket<UpdateUserTypePacketData> {
  static final DataParser parser =
      DataParserBuilder().bigEndian().uint8().sint8().build();
  int id = 0x0D;
  int length = 2;

  UpdateUserTypePacketData decode(List<int> data) {
    var decodedData = parser.decode(data);
    return UpdateUserTypePacketData(userType: decodedData[1]);
  }

  @override
  List<int> encode(UpdateUserTypePacketData data) {
    return parser.encode([data.id, data.userType]);
  }
}

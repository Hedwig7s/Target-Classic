import 'dart:convert';

import '../../dataparser/builder.dart';
import '../../dataparser/parser.dart';

abstract class PacketData {
  abstract final int id;
  List<int> encode();
}

class IdentificationPacketData implements PacketData {
  static DataParser _parser =
      DataParserBuilder()
          .uint8()
          .uint8()
          .fixedString(64, Encoding.getByName('ascii')!, padding: ' ')
          .fixedString(64, Encoding.getByName('ascii')!, padding: ' ')
          .uint8()
          .build();

  final int id;
  final int protocolVersion;
  final String name;
  final String keyOrMotd;
  final int userType;
  IdentificationPacketData({
    this.id = 0x00,
    required this.protocolVersion,
    required this.name,
    required this.keyOrMotd,
    required this.userType,
  });
  static IdentificationPacketData decodeFromData(List<int> data) {
    var decodedData = _parser.decode(data);
    return IdentificationPacketData(
      id: decodedData[0],
      protocolVersion: decodedData[1],
      name: decodedData[2],
      keyOrMotd: decodedData[3],
      userType: decodedData[4],
    );
  }

  @override
  List<int> encode() {
    var encodedData = _parser.encode([
      id,
      protocolVersion,
      name,
      keyOrMotd,
      userType,
    ]);
    return encodedData;
  }
}

class PingPacketData implements PacketData {
  @override
  final int id = 0x01;

  static DataParser _parser = DataParserBuilder().uint8().build();

  PingPacketData();

  static PingPacketData decodeFromData(List<int> data) {
    return PingPacketData();
  }

  @override
  List<int> encode() {
    return _parser.encode([id]);
  }
}

class LevelInitializePacketData implements PacketData {
  @override
  final int id = 0x02;

  static DataParser _parser = DataParserBuilder().uint8().build();

  LevelInitializePacketData();

  static LevelInitializePacketData decodeFromData(List<int> data) {
    return LevelInitializePacketData();
  }

  @override
  List<int> encode() {
    return _parser.encode([id]);
  }
}

class LevelDataChunkPacketData implements PacketData {
  @override
  final int id = 0x03;
  final int chunkLength;
  final List<int> chunkData;
  final int percentComplete;

  static DataParser _parser =
      DataParserBuilder().uint8().uint16().bytes(1024).uint8().build();

  LevelDataChunkPacketData({
    required this.chunkLength,
    required this.chunkData,
    required this.percentComplete,
  });

  static LevelDataChunkPacketData decodeFromData(List<int> data) {
    var decodedData = _parser.decode(data);
    return LevelDataChunkPacketData(
      chunkLength: decodedData[1],
      chunkData: decodedData[2],
      percentComplete: decodedData[3],
    );
  }

  @override
  List<int> encode() {
    return _parser.encode([id, chunkLength, chunkData, percentComplete]);
  }
}

class LevelFinalizePacketData implements PacketData {
  @override
  final int id = 0x04;
  final int sizeX;
  final int sizeY;
  final int sizeZ;

  static DataParser _parser =
      DataParserBuilder().uint8().uint16().uint16().uint16().build();

  LevelFinalizePacketData({
    required this.sizeX,
    required this.sizeY,
    required this.sizeZ,
  });

  static LevelFinalizePacketData decodeFromData(List<int> data) {
    var decodedData = _parser.decode(data);
    return LevelFinalizePacketData(
      sizeX: decodedData[1],
      sizeY: decodedData[2],
      sizeZ: decodedData[3],
    );
  }

  @override
  List<int> encode() {
    return _parser.encode([id, sizeX, sizeY, sizeZ]);
  }
}

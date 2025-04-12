import 'dart:convert';

import '../../networking/connection.dart';
import '../../dataparser/builder.dart';
import '../../dataparser/parser.dart';
import '../../networking/packet.dart';
import 'packetdata.dart';

class IdentificationPacket7 extends Packet
    with SendablePacket<IdentificationPacketData>, ReceivablePacket {
  int id = 0x00;
  int length = 131;

  IdentificationPacketData decode(List<int> data) {
    return IdentificationPacketData.decodeFromData(data);
  }

  @override
  List<int> encode(IdentificationPacketData data) {
    return data.encode();
  }

  @override
  Future<void> receive(Connection connection, List<int> data) async {
    var decodedData = decode(data);
    print('Received Identification Packet: $decodedData');
  }
}

class PingPacket7 extends Packet
    with SendablePacket<PingPacketData>, ReceivablePacket {
  int id = 0x02;
  int length = 1;

  PingPacketData decode(List<int> data) {
    return PingPacketData.decodeFromData(data);
  }

  @override
  List<int> encode(PingPacketData data) {
    return data.encode();
  }

  @override
  Future<void> receive(Connection connection, List<int> data) async {
    // Do nothing
    // This packet is just a ping, no data to process
  }
}

class LevelInitializePacket7 extends Packet
    with SendablePacket<LevelInitializePacketData>, ReceivablePacket {
  int id = 0x02;
  int length = 1;

  LevelInitializePacketData decode(List<int> data) {
    return LevelInitializePacketData.decodeFromData(data);
  }

  @override
  List<int> encode(LevelInitializePacketData data) {
    return data.encode();
  }

  @override
  Future<void> receive(Connection connection, List<int> data) async {
    var decodedData = decode(data);
    print('Received Level Initialize Packet: $decodedData');
  }
}

class LevelDataChunkPacket7 extends Packet
    with SendablePacket<LevelDataChunkPacketData>, ReceivablePacket {
  int id = 0x03;
  int length = 1028;

  LevelDataChunkPacketData decode(List<int> data) {
    return LevelDataChunkPacketData.decodeFromData(data);
  }

  @override
  List<int> encode(LevelDataChunkPacketData data) {
    return data.encode();
  }

  @override
  Future<void> receive(Connection connection, List<int> data) async {
    var decodedData = decode(data);
    print('Received Level Data Chunk Packet: $decodedData');
  }
}

class LevelFinalizePacket7 extends Packet
    with SendablePacket<LevelFinalizePacketData>, ReceivablePacket {
  int id = 0x04;
  int length = 7;

  LevelFinalizePacketData decode(List<int> data) {
    return LevelFinalizePacketData.decodeFromData(data);
  }

  @override
  List<int> encode(LevelFinalizePacketData data) {
    return data.encode();
  }

  @override
  Future<void> receive(Connection connection, List<int> data) async {
    var decodedData = decode(data);
    print('Received Level Finalize Packet: $decodedData');
  }
}

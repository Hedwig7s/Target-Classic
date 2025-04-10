import 'dart:convert';

import '../../networking/connection.dart';
import '../../dataparser/builder.dart';
import '../../dataparser/parser.dart';
import '../../networking/packet.dart';
import 'packetdataenums.dart';

class IdentificationPacket7 extends Packet
    with SendablePacket, ReceivablePacket {
  int id = 0x00;
  int get length => this.parser.size ?? 131;
  DataParser<IdentificationPacketData> parser =
      DataParserBuilder<IdentificationPacketData>()
              .uint8(IdentificationPacketData.id)
              .uint8(IdentificationPacketData.protocolVersion)
              .fixedString(
                IdentificationPacketData.name,
                64,
                Encoding.getByName('ascii')!,
                padding: ' ',
              )
              .fixedString(
                IdentificationPacketData.keyOrMotd,
                64,
                Encoding.getByName('ascii')!,
                padding: ' ',
              )
              .uint8(IdentificationPacketData.userType)
              .build()
          as DataParser<IdentificationPacketData>;
  @override
  Future<void> receive(Connection connection, List<int> data) async {
    var decodedData = decode(data) as Map<IdentificationPacketData, dynamic>;
    print('Received Identification Packet: $decodedData');
  }
}

class PingPacket extends Packet with SendablePacket, ReceivablePacket {
  int id = 0x02;
  int get length => this.parser.size ?? 1;
  DataParser<PingPacketData> parser =
      DataParserBuilder<PingPacketData>().uint8(PingPacketData.id).build()
          as DataParser<PingPacketData>;
  @override
  Future<void> receive(Connection connection, List<int> data) async {
    // Do nothing
    // This packet is just a ping, no data to process
  }
}

class LevelInitializePacket extends Packet with SendablePacket {
  int id = 0x02;
  int get length => this.parser.size ?? 1;
  DataParser<LevelInitializePacketData> parser =
      DataParserBuilder<LevelInitializePacketData>()
              .uint8(LevelInitializePacketData.id)
              .build()
          as DataParser<LevelInitializePacketData>;
}

class LevelDataChunkPacket extends Packet with SendablePacket {
  int id = 0x03;
  int get length => this.parser.size ?? 1;
  DataParser<LevelDataChunkPacketData> parser =
      DataParserBuilder<LevelDataChunkPacketData>()
              .uint8(LevelDataChunkPacketData.id)
              .uint16(LevelDataChunkPacketData.chunkLength)
              .raw(LevelDataChunkPacketData.chunkData, 1024)
              .uint8(LevelDataChunkPacketData.percentComplete)
              .build()
          as DataParser<LevelDataChunkPacketData>;
}

class LevelFinalizePacket extends Packet with SendablePacket {
  int id = 0x04;
  int get length => this.parser.size ?? 1;
  DataParser<LevelFinalizePacketData> parser =
      DataParserBuilder<LevelFinalizePacketData>()
              .uint8(LevelFinalizePacketData.id)
              .uint16(LevelFinalizePacketData.sizeX)
              .uint16(LevelFinalizePacketData.sizeY)
              .uint16(LevelFinalizePacketData.sizeZ)
              .build()
          as DataParser<LevelFinalizePacketData>;
}

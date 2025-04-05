import 'dart:convert';

import '../../connection.dart';
import '../../dataparser/builder.dart';
import '../../dataparser/parser.dart';
import '../../packet.dart';
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
              )
              .fixedString(
                IdentificationPacketData.keyOrMotd,
                64,
                Encoding.getByName('ascii')!,
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

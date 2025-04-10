import '../../networking/packet.dart';
import '../../networking/protocol.dart';
import 'packets.dart';

class Protocol7 extends Protocol {
  @override
  int get version => 7;
  Map<PacketIds, Packet> get packets => {
    PacketIds.identification: IdentificationPacket7(),
  };
}

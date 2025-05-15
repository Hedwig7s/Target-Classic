import '../../packet.dart';
import '../../protocol.dart';
import 'packets.dart';

class Protocol7 extends Protocol {
  @override
  int get version => 7;
  Map<PacketIds, Packet> get packets => {
    PacketIds.identification: IdentificationPacket7(),
    PacketIds.ping: PingPacket7(),
    PacketIds.levelInitialize: LevelInitializePacket7(),
    PacketIds.levelDataChunk: LevelDataChunkPacket7(),
    PacketIds.levelFinalize: LevelFinalizePacket7(),
    PacketIds.setBlockClient: SetBlockClientPacket7(),
    PacketIds.setBlockServer: SetBlockServerPacket7(),
    PacketIds.spawnPlayer: SpawnPlayerPacket7(),
  };
}

import 'package:target_classic/networking/packet.dart';
import 'package:target_classic/networking/protocol.dart';
import 'packets.dart';

class Protocol7 extends Protocol {
  @override
  int get version => 7;
  @override
  Map<PacketIds, Packet> get packets => {
    PacketIds.identification: IdentificationPacket7(),
    PacketIds.ping: PingPacket7(),
    PacketIds.levelInitialize: LevelInitializePacket7(),
    PacketIds.levelDataChunk: LevelDataChunkPacket7(),
    PacketIds.levelFinalize: LevelFinalizePacket7(),
    PacketIds.setBlockClient: SetBlockClientPacket7(),
    PacketIds.setBlockServer: SetBlockServerPacket7(),
    PacketIds.spawnPlayer: SpawnPlayerPacket7(),
    PacketIds.setPositionAndOrientation: SetPositionAndOrientationPacket7(),
    PacketIds.positionAndOrientationUpdate:
        PositionAndOrientationUpdatePacket7(),
    PacketIds.positionUpdate: PositionUpdatePacket7(),
    PacketIds.orientationUpdate: OrientationUpdatePacket7(),
    PacketIds.despawnPlayer: DespawnPlayerPacket7(),
    PacketIds.message: MessagePacket7(),
    PacketIds.disconnectPlayer: DisconnectPlayerPacket7(),
    PacketIds.updateUserType: UpdateUserTypePacket7(),
  };
}

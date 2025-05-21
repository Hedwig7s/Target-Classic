import 'dart:typed_data';

import 'packet.dart';

// Index lines up with the packet id
enum PacketIds {
  identification,
  ping,
  levelInitialize,
  levelDataChunk,
  levelFinalize,
  setBlockClient,
  setBlockServer,
  spawnPlayer,
  setPositionAndOrientation,
  positionAndOrientationUpdate,
  positionUpdate,
  orientationUpdate,
  despawnPlayer,
  message,
  disconnectPlayer,
  updateUserType,
}

abstract class Protocol {
  int get version;
  Map<PacketIds, Packet> get packets;
  bool identify(Uint8List data) {
    if (data.length < 2) {
      return false;
    }
    return data[1] == version;
  }

  T assertPacket<T extends Packet>(PacketIds id) {
    Packet? packet = packets[id];
    if (packet == null)
      throw Exception("Packet $id doesn't exist for protocol $version");
    if (packet is! T)
      throw Exception(
        "Packet $id is not of the expected type. Expected $T, got ${packet.runtimeType}",
      );
    return packet;
  }

  T? getPacket<T extends Packet>(PacketIds id) {
    try {
      return assertPacket<T>(id);
    } catch (e) {
      return null;
    }
  }
}

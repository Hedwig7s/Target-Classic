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
}

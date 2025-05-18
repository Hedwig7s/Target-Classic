import '../../../datatypes.dart';

abstract class PacketData {
  final int id;

  const PacketData({required this.id});

  @override
  String toString();
}

class IdentificationPacketData implements PacketData {
  @override
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

  @override
  String toString() {
    return 'IdentificationPacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'protocolVersion: $protocolVersion, '
        'name: "$name", '
        'keyOrMotd: "$keyOrMotd", '
        'userType: $userType}';
  }
}

class PingPacketData implements PacketData {
  @override
  final int id;

  PingPacketData({this.id = 0x01});

  @override
  String toString() {
    return 'PingPacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}}';
  }
}

class LevelInitializePacketData implements PacketData {
  @override
  final int id;

  LevelInitializePacketData({this.id = 0x02});

  @override
  String toString() {
    return 'LevelInitializePacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}}';
  }
}

class LevelDataChunkPacketData implements PacketData {
  @override
  final int id;
  final int chunkLength;
  final List<int> chunkData;
  final int percentComplete;

  LevelDataChunkPacketData({
    this.id = 0x03,
    required this.chunkLength,
    required this.chunkData,
    required this.percentComplete,
  });

  @override
  String toString() {
    return 'LevelDataChunkPacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'chunkLength: $chunkLength, '
        'chunkData: [${chunkData.length} bytes], '
        'percentComplete: $percentComplete%}';
  }
}

class LevelFinalizePacketData implements PacketData {
  @override
  final int id;
  final int sizeX;
  final int sizeY;
  final int sizeZ;

  LevelFinalizePacketData({
    this.id = 0x04,
    required this.sizeX,
    required this.sizeY,
    required this.sizeZ,
  });

  @override
  String toString() {
    return 'LevelFinalizePacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'sizeX: $sizeX, '
        'sizeY: $sizeY, '
        'sizeZ: $sizeZ}';
  }
}

class SetBlockClientPacketData implements PacketData {
  @override
  final int id;
  final Vector3<int> position;
  final int mode;
  final int blockId;

  SetBlockClientPacketData({
    this.id = 0x05,
    required this.position,
    required this.mode,
    required this.blockId,
  });

  @override
  String toString() {
    return 'SetBlockClientPacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'position: $position, '
        'mode: $mode, '
        'blockId: $blockId}';
  }
}

class SetBlockServerPacketData implements PacketData {
  @override
  final int id;
  final Vector3<int> position;
  final int blockId;

  SetBlockServerPacketData({
    this.id = 0x06,
    required this.position,
    required this.blockId,
  });

  @override
  String toString() {
    return 'SetBlockServerPacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'position: $position, '
        'blockId: $blockId}';
  }
}

class SpawnPlayerPacketData implements PacketData {
  @override
  final int id;
  final int playerId;
  final String name;
  final EntityPosition position;

  SpawnPlayerPacketData({
    this.id = 0x07,
    required this.playerId,
    required this.name,
    required this.position,
  });

  @override
  String toString() {
    return 'SpawnPlayerPacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'playerId: $playerId, '
        'name: "$name", '
        'position: "$position"}';
  }
}

class SetPositionAndOrientationPacketData implements PacketData {
  @override
  final int id;
  final int playerId;
  final EntityPosition position;

  SetPositionAndOrientationPacketData({
    this.id = 0x08,
    required this.playerId,
    required this.position,
  });

  @override
  String toString() {
    return 'SetPositionAndOrientationPacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'playerId: $playerId, '
        'position: $position}';
  }
}

class PositionAndOrientationUpdate implements PacketData {
  @override
  final int id;
  final int playerId;
  final EntityPosition position;

  PositionAndOrientationUpdate({
    this.id = 0x09,
    required this.playerId,
    required this.position,
  });

  @override
  String toString() {
    return 'PositionAndOrientationUpdate{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'playerId: $playerId, '
        'position: $position}';
  }
}

class PositionUpdatePacketData implements PacketData {
  @override
  final int id;
  final int playerId;
  final Vector3<double> position;

  PositionUpdatePacketData({
    this.id = 0x0A,
    required this.playerId,
    required this.position,
  });

  @override
  String toString() {
    return 'PositionUpdatePacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'playerId: $playerId, '
        'position: $position}';
  }
}

class OrientationUpdatePacketData implements PacketData {
  @override
  final int id;
  final int playerId;
  final EntityPosition position;

  OrientationUpdatePacketData({
    this.id = 0x0B,
    required this.playerId,
    required this.position,
  });

  @override
  String toString() {
    return 'OrientationUpdatePacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'playerId: $playerId, '
        'position: $position}';
  }
}

class DespawnPlayerPacketData implements PacketData {
  @override
  final int id;
  final int playerId;

  DespawnPlayerPacketData({this.id = 0x0C, required this.playerId});

  @override
  String toString() {
    return 'DespawnPlayerPacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'playerId: $playerId}';
  }
}

class MessagePacketData implements PacketData {
  @override
  final int id;
  final int playerId;
  final String message;

  MessagePacketData({
    this.id = 0x0D,
    required this.playerId,
    required this.message,
  });

  @override
  String toString() {
    return 'MessagePacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'playerId: $playerId, '
        'message: "$message"}';
  }
}

class DisconnectPlayerPacketData implements PacketData {
  @override
  final int id;
  final String reason;

  DisconnectPlayerPacketData({this.id = 0x0E, required this.reason});

  @override
  String toString() {
    return 'DisconnectPlayerPacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'reason: "$reason"}';
  }
}

class UpdateUserTypePacketData implements PacketData {
  @override
  final int id;
  final int userType;

  UpdateUserTypePacketData({this.id = 0x0F, required this.userType});

  @override
  String toString() {
    return 'UpdateUserTypePacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'userType: $userType}';
  }
}

abstract class PacketData {
  abstract final int id;

  @override
  String toString();
}

class IdentificationPacketData implements PacketData {
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
  final int id = 0x01;

  PingPacketData();

  @override
  String toString() {
    return 'PingPacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}}';
  }
}

class LevelInitializePacketData implements PacketData {
  @override
  final int id = 0x02;

  LevelInitializePacketData();

  @override
  String toString() {
    return 'LevelInitializePacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}}';
  }
}

class LevelDataChunkPacketData implements PacketData {
  @override
  final int id = 0x03;
  final int chunkLength;
  final List<int> chunkData;
  final int percentComplete;

  LevelDataChunkPacketData({
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
  final int id = 0x04;
  final int sizeX;
  final int sizeY;
  final int sizeZ;

  LevelFinalizePacketData({
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
  final int id = 0x05;
  final int x;
  final int y;
  final int z;
  final int mode;
  final int blockId;

  SetBlockClientPacketData({
    required this.x,
    required this.y,
    required this.z,
    required this.mode,
    required this.blockId,
  });
  @override
  String toString() {
    return 'SetBlockClientPacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'x: $x, '
        'y: $y, '
        'z: $z, '
        'mode: $mode, '
        'blockId: $blockId}';
  }
}

class SetBlockServerPacketData implements PacketData {
  @override
  final int id = 0x06;
  final int x;
  final int y;
  final int z;
  final int blockId;

  SetBlockServerPacketData({
    required this.x,
    required this.y,
    required this.z,
    required this.blockId,
  });

  @override
  String toString() {
    return 'SetBlockServerPacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'x: $x, '
        'y: $y, '
        'z: $z, '
        'blockId: $blockId}';
  }
}

class SpawnPlayerPacketData implements PacketData {
  @override
  final int id = 0x07;
  final int playerId;
  final String name;
  final double x;
  final double y;
  final double z;
  final int yaw;
  final int pitch;

  SpawnPlayerPacketData({
    required this.playerId,
    required this.name,
    required this.x,
    required this.y,
    required this.z,
    required this.yaw,
    required this.pitch,
  });
  @override
  String toString() {
    return 'SpawnPlayerPacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'playerId: $playerId, '
        'name: "$name", '
        'x: $x, '
        'y: $y, '
        'z: $z, '
        'yaw: $yaw, '
        'pitch: $pitch}';
  }
}

class SetPositionAndOrientationPacketData implements PacketData {
  @override
  final int id = 0x08;
  final int playerId;
  final double x;
  final double y;
  final double z;
  final int yaw;
  final int pitch;

  SetPositionAndOrientationPacketData({
    required this.playerId,
    required this.x,
    required this.y,
    required this.z,
    required this.yaw,
    required this.pitch,
  });

  @override
  String toString() {
    return 'SetPositionAndOrientationPacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'playerId: $playerId, '
        'x: $x, '
        'y: $y, '
        'z: $z, '
        'yaw: $yaw, '
        'pitch: $pitch}';
  }
}

class PositionAndOrientationUpdate implements PacketData {
  @override
  final int id = 0x09;
  final int playerId;
  final double x;
  final double y;
  final double z;
  final int yaw;
  final int pitch;

  PositionAndOrientationUpdate({
    required this.playerId,
    required this.x,
    required this.y,
    required this.z,
    required this.yaw,
    required this.pitch,
  });

  @override
  String toString() {
    return 'PositionAndOrientationUpdate{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'playerId: $playerId, '
        'x: $x, '
        'y: $y, '
        'z: $z, '
        'yaw: $yaw, '
        'pitch: $pitch}';
  }
}

class PositionUpdatePacketData implements PacketData {
  @override
  final int id = 0x0A;
  final int playerId;
  final double x;
  final double y;
  final double z;

  PositionUpdatePacketData({
    required this.playerId,
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  String toString() {
    return 'PositionUpdatePacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'playerId: $playerId, '
        'x: $x, '
        'y: $y, '
        'z: $z}';
  }
}

class OrientationUpdatePacketData implements PacketData {
  @override
  final int id = 0x0B;
  final int playerId;
  final int yaw;
  final int pitch;

  OrientationUpdatePacketData({
    required this.playerId,
    required this.yaw,
    required this.pitch,
  });

  @override
  String toString() {
    return 'OrientationUpdatePacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'playerId: $playerId, '
        'yaw: $yaw, '
        'pitch: $pitch}';
  }
}

class DespawnPlayerPacketData implements PacketData {
  @override
  final int id = 0x0C;
  final int playerId;

  DespawnPlayerPacketData({required this.playerId});

  @override
  String toString() {
    return 'DespawnPlayerPacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'playerId: $playerId}';
  }
}

class MessagePacketData implements PacketData {
  @override
  final int id = 0x0D;
  final int playerId;
  final String message;

  MessagePacketData({required this.playerId, required this.message});
  @override
  String toString() {
    return 'MessagePacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'playerId: $playerId, '
        'message: "$message"}';
  }
}

class DisconnectPlayerPacketData implements PacketData {
  @override
  final int id = 0x0E;
  final String reason;
  DisconnectPlayerPacketData({required this.reason});
  @override
  String toString() {
    return 'DisconnectPlayerPacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'reason: "$reason"}';
  }
}

class UpdateUserTypePacketData implements PacketData {
  @override
  final int id = 0x0F;
  final int userType;

  UpdateUserTypePacketData({required this.userType});
  @override
  String toString() {
    return 'UpdateUserTypePacketData{id: 0x${id.toRadixString(16).padLeft(2, '0')}, '
        'userType: $userType}';
  }
}

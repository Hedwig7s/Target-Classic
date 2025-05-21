import 'package:freezed_annotation/freezed_annotation.dart';

import '../datatypes.dart';

part 'packetdata.freezed.dart';

abstract interface class PacketData {
  final int id;

  const PacketData({required this.id});

  @override
  String toString();
}

@freezed
abstract class IdentificationPacketData
    with _$IdentificationPacketData
    implements PacketData {
  const factory IdentificationPacketData({
    @Default(0x00) int id,
    required int protocolVersion,
    required String name,
    required String keyOrMotd,
    required int userType,
  }) = _IdentificationPacketData;
}

@freezed
abstract class PingPacketData with _$PingPacketData implements PacketData {
  const factory PingPacketData({@Default(0x01) int id}) =
      _PingPacketData;
}

@freezed
abstract class LevelInitializePacketData
    with _$LevelInitializePacketData
    implements PacketData {
  const factory LevelInitializePacketData({@Default(0x02) int id}) =
      _LevelInitializePacketData;
}

@freezed
abstract class LevelDataChunkPacketData
    with _$LevelDataChunkPacketData
    implements PacketData {
  const factory LevelDataChunkPacketData({
    @Default(0x03) int id,
    required int chunkLength,
    required List<int> chunkData,
    required int percentComplete,
  }) = _LevelDataChunkPacketData;
}

@freezed
abstract class LevelFinalizePacketData
    with _$LevelFinalizePacketData
    implements PacketData {
  const factory LevelFinalizePacketData({
    @Default(0x04) int id,
    required final int sizeX,
    required final int sizeY,
    required final int sizeZ,
  }) = _LevelFinalizePacketData;
}

@freezed
abstract class SetBlockClientPacketData
    with _$SetBlockClientPacketData
    implements PacketData {
  const factory SetBlockClientPacketData({
    @Default(0x05) int id,
    required Vector3<int> position,
    required int mode,
    required int blockId,
  }) = _SetBlockClientPacketData;
}

@freezed
abstract class SetBlockServerPacketData
    with _$SetBlockServerPacketData
    implements PacketData {
  const factory SetBlockServerPacketData({
    @Default(0x06) int id,
    required Vector3<int> position,
    required int blockId,
  }) = _SetBlockServerPacketData;
}

@freezed
abstract class SpawnPlayerPacketData
    with _$SpawnPlayerPacketData
    implements PacketData {
  const factory SpawnPlayerPacketData({
    @Default(0x07) int id,
    required int playerId,
    required String name,
    required EntityPosition position,
  }) = _SpawnPlayerPacketData;
}

@freezed
abstract class SetPositionAndOrientationPacketData
    with _$SetPositionAndOrientationPacketData
    implements PacketData {
  const factory SetPositionAndOrientationPacketData({
    @Default(0x08) int id,
    required int playerId,
    required EntityPosition position,
  }) = _SetPositionAndOrientationPacketData;
}

@freezed
abstract class PositionAndOrientationUpdatePacketData
    with _$PositionAndOrientationUpdatePacketData
    implements PacketData {
  const factory PositionAndOrientationUpdatePacketData({
    @Default(0x09) int id,
    required int playerId,
    required EntityPosition position,
  }) = _PositionAndOrientationUpdatePacketData;
}

@freezed
abstract class PositionUpdatePacketData
    with _$PositionUpdatePacketData
    implements PacketData {
  const factory PositionUpdatePacketData({
    @Default(0x0A) int id,
    required int playerId,
    required Vector3<double> position,
  }) = _PositionUpdatePacketData;
}

@freezed
abstract class OrientationUpdatePacketData
    with _$OrientationUpdatePacketData
    implements PacketData {
  const factory OrientationUpdatePacketData({
    @Default(0x0B) int id,
    required int playerId,
    required EntityPosition position,
  }) = _OrientationUpdatePacketData;
}

@freezed
abstract class DespawnPlayerPacketData
    with _$DespawnPlayerPacketData
    implements PacketData {
  const factory DespawnPlayerPacketData({
    @Default(0x0C) int id,
    required int playerId,
  }) = _DespawnPlayerPacketData;
}

@freezed
abstract class MessagePacketData
    with _$MessagePacketData
    implements PacketData {
  const factory MessagePacketData({
    @Default(0x0D) int id,
    required int playerId,
    required String message,
  }) = _MessagePacketData;
}

@freezed
abstract class DisconnectPlayerPacketData
    with _$DisconnectPlayerPacketData
    implements PacketData {
  const factory DisconnectPlayerPacketData({
    @Default(0x0E) int id,
    required String reason,
  }) = _DisconnectPlayerPacketData;
}

@freezed
abstract class UpdateUserTypePacketData
    with _$UpdateUserTypePacketData
    implements PacketData {
  const factory UpdateUserTypePacketData({
    @Default(0x0F) int id,
    required int userType,
  }) = _UpdateUserTypePacketData;
}

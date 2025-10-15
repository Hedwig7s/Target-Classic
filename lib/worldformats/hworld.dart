import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../dataparser/builder.dart';
import '../dataparser/parser.dart';
import 'worldformat.dart';
import '../world.dart';
import '../datatypes.dart';

class HeaderV2 {
  static final DataParser _parser =
      DataParserBuilder()
          .littleEndian()
          .uint32() // version
          .uint16() // sizeX
          .uint16() // sizeY
          .uint16() // sizeZ
          .uint16() // spawnX
          .uint16() // spawnY
          .uint16() // spawnZ
          .uint8() // spawnYaw
          .uint8() // spawnPitch
          .build();

  final int version;
  final int sizeX;
  final int sizeY;
  final int sizeZ;
  final int spawnX;
  final int spawnY;
  final int spawnZ;
  final int spawnYaw;
  final int spawnPitch;

  HeaderV2({
    required this.version,
    required this.sizeX,
    required this.sizeY,
    required this.sizeZ,
    required this.spawnX,
    required this.spawnY,
    required this.spawnZ,
    required this.spawnYaw,
    required this.spawnPitch,
  });

  static HeaderV2 decodeFromData(List<int> data) {
    var decoded = _parser.decode(data);
    return HeaderV2(
      version: decoded[0],
      sizeX: decoded[1],
      sizeY: decoded[2],
      sizeZ: decoded[3],
      spawnX: decoded[4],
      spawnY: decoded[5],
      spawnZ: decoded[6],
      spawnYaw: decoded[7],
      spawnPitch: decoded[8],
    );
  }

  List<int> encode() {
    return _parser.encode([
      version,
      sizeX,
      sizeY,
      sizeZ,
      spawnX,
      spawnY,
      spawnZ,
      spawnYaw,
      spawnPitch,
    ]);
  }
}

class HeaderV4 extends HeaderV2 {
  static final DataParser _parser =
      DataParserBuilder()
          .littleEndian()
          .uint32() // version
          .fixedString(6, Encoding.getByName('ascii')!) // identifier
          .uint16() // sizeX
          .uint16() // sizeY
          .uint16() // sizeZ
          .uint16() // spawnX
          .uint16() // spawnY
          .uint16() // spawnZ
          .uint8() // spawnYaw
          .uint8() // spawnPitch
          .uint32() // blockDataSize
          .build();

  final String identifier;
  final int blockDataSize;

  HeaderV4({
    required version,
    required this.identifier,
    required sizeX,
    required sizeY,
    required sizeZ,
    required spawnX,
    required spawnY,
    required spawnZ,
    required spawnYaw,
    required spawnPitch,
    required this.blockDataSize,
  }) : super(
         version: version,
         sizeX: sizeX,
         sizeY: sizeY,
         sizeZ: sizeZ,
         spawnX: spawnX,
         spawnY: spawnY,
         spawnZ: spawnZ,
         spawnYaw: spawnYaw,
         spawnPitch: spawnPitch,
       );

  static HeaderV4 decodeFromData(List<int> data) {
    var decoded = _parser.decode(data);
    return HeaderV4(
      version: decoded[0],
      identifier: decoded[1],
      sizeX: decoded[2],
      sizeY: decoded[3],
      sizeZ: decoded[4],
      spawnX: decoded[5],
      spawnY: decoded[6],
      spawnZ: decoded[7],
      spawnYaw: decoded[8],
      spawnPitch: decoded[9],
      blockDataSize: decoded[10],
    );
  }

  @override
  List<int> encode() {
    return _parser.encode([
      version,
      identifier,
      sizeX,
      sizeY,
      sizeZ,
      spawnX,
      spawnY,
      spawnZ,
      spawnYaw,
      spawnPitch,
      blockDataSize,
    ]);
  }
}

class BlockData {
  static final DataParser _parser =
      DataParserBuilder()
          .littleEndian()
          .uint8() // blockId
          .uint32() // blockCount
          .build();

  final int blockId;
  final int blockCount;

  BlockData({required this.blockId, required this.blockCount});

  static BlockData decodeFromData(List<int> data) {
    var decoded = _parser.decode(data);
    return BlockData(blockId: decoded[0], blockCount: decoded[1]);
  }

  List<int> encode() {
    return _parser.encode([blockId, blockCount]);
  }
}

class HWorldFormat extends WorldFormat {
  HWorldFormat._privateConstructor();
  static final HWorldFormat _instance = HWorldFormat._privateConstructor();
  factory HWorldFormat() {
    return _instance;
  }
  @override
  List<String> get extensions => ['hworld'];

  @override
  bool identify(List<int> data) {
    return data.length > 10 &&
        AsciiDecoder().convert(data.sublist(5, 12)) == 'HWORLD';
  }

  @override
  WorldBuilder deserialize(List<int> data) {
    var version = ByteData.sublistView(
      Uint8List.fromList(data),
    ).getUint32(0, Endian.little);

    int sizeX,
        sizeY,
        sizeZ,
        spawnX,
        spawnY,
        spawnZ,
        spawnYaw,
        spawnPitch,
        blockDataSize;
    int headerSize;

    if (version == 4) {
      var header = HeaderV4.decodeFromData(data);
      sizeX = header.sizeX;
      sizeY = header.sizeY;
      sizeZ = header.sizeZ;
      spawnX = header.spawnX;
      spawnY = header.spawnY;
      spawnZ = header.spawnZ;
      spawnYaw = header.spawnYaw;
      spawnPitch = header.spawnPitch;
      blockDataSize = header.blockDataSize;
      headerSize = HeaderV4._parser.size!;
    } else if (version >= 2 && version < 4) {
      var header = HeaderV2.decodeFromData(data);
      sizeX = header.sizeX;
      sizeY = header.sizeY;
      sizeZ = header.sizeZ;
      spawnX = header.spawnX;
      spawnY = header.spawnY;
      spawnZ = header.spawnZ;
      spawnYaw = header.spawnYaw;
      spawnPitch = header.spawnPitch;
      blockDataSize = data.length - HeaderV2._parser.size!;
      headerSize = HeaderV2._parser.size!;
    } else {
      throw Exception('Unsupported version: $version');
    }

    var extractedBlocks = data.sublist(
      headerSize,
      version == 4 ? headerSize + blockDataSize : null,
    );

    if (version >= 3) {
      ZLibDecoder zlib = ZLibDecoder();
      extractedBlocks = zlib.convert(extractedBlocks);
    }

    List<int> blocks = List.filled(sizeX * sizeY * sizeZ, 0);
    int offset = 0;
    for (int i = 0; i < extractedBlocks.length; i += 5) {
      final block = BlockData.decodeFromData(extractedBlocks.sublist(i, i + 5));
      int id = block.blockId;
      int count = block.blockCount;

      for (int j = 0; j < count; j++) {
        blocks[offset++] = id;
      }
    }

    return WorldBuilder(
      name: null,
      size: Vector3I(sizeX, sizeY, sizeZ),
      spawnPoint: EntityPosition(
        spawnX.toDouble(),
        spawnY.toDouble(),
        spawnZ.toDouble(),
        spawnYaw,
        spawnPitch,
      ),
      blocks: blocks,
    );
  }

  @override
  List<int> serialize(World world) {
    List<int> blockData = [];
    int? currentId;
    int count = 0;

    for (int i = 0; i < world.blocks.length; i++) {
      if (world.blocks[i] == currentId && currentId != null) {
        count++;
      } else {
        if (count > 0) {
          blockData.addAll(
            BlockData(blockId: currentId!, blockCount: count).encode(),
          );
        }
        currentId = world.blocks[i];
        count = 1;
      }
    }

    if (count > 0) {
      blockData.addAll(
        BlockData(blockId: currentId!, blockCount: count).encode(),
      );
    }

    ZLibEncoder zlib = ZLibEncoder();
    List<int> compressedBlocks = zlib.convert(blockData);

    HeaderV4 header = HeaderV4(
      version: 4,
      identifier: 'HWORLD',
      sizeX: world.size.x,
      sizeY: world.size.y,
      sizeZ: world.size.z,
      spawnX: world.spawnPoint.x.round(),
      spawnY: world.spawnPoint.y.round(),
      spawnZ: world.spawnPoint.z.round(),
      spawnYaw: world.spawnPoint.yaw,
      spawnPitch: world.spawnPoint.pitch,
      blockDataSize: compressedBlocks.length,
    );

    List<int> result = List.from(header.encode());
    result.addAll(compressedBlocks);

    return result;
  }
}

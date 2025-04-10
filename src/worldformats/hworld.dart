import 'dart:convert';
import 'dart:io';

import '../dataparser/builder.dart';
import 'worldformat.dart';
import '../world.dart';
import '../datatypes.dart';

enum HEADERV2_PARSER_KEYS {
  VERSION,
  SIZEX,
  SIZEY,
  SIZEZ,
  SPAWNX,
  SPAWNY,
  SPAWNZ,
  SPAWNYAW,
  SPAWNPITCH,
}

enum HEADERV4_PARSER_KEYS {
  VERSION,
  IDENTIFIER,
  SIZEX,
  SIZEY,
  SIZEZ,
  SPAWNX,
  SPAWNY,
  SPAWNZ,
  SPAWNYAW,
  SPAWNPITCH,
  BLOCK_DATA_SIZE,
}

final HEADERV2_PARSER =
    new DataParserBuilder<HEADERV2_PARSER_KEYS>()
        .uint32(HEADERV2_PARSER_KEYS.VERSION)
        .uint16(HEADERV2_PARSER_KEYS.SIZEX)
        .uint16(HEADERV2_PARSER_KEYS.SIZEY)
        .uint16(HEADERV2_PARSER_KEYS.SIZEZ)
        .uint16(HEADERV2_PARSER_KEYS.SPAWNX)
        .uint16(HEADERV2_PARSER_KEYS.SPAWNY)
        .uint16(HEADERV2_PARSER_KEYS.SPAWNZ)
        .uint8(HEADERV2_PARSER_KEYS.SPAWNYAW)
        .uint8(HEADERV2_PARSER_KEYS.SPAWNPITCH)
        .build();

final HEADERV4_PARSER =
    new DataParserBuilder<HEADERV4_PARSER_KEYS>()
        .uint32(HEADERV4_PARSER_KEYS.VERSION)
        .fixedString(
          HEADERV4_PARSER_KEYS.IDENTIFIER,
          6,
          Encoding.getByName('ascii')!,
        )
        .uint16(HEADERV4_PARSER_KEYS.SIZEX)
        .uint16(HEADERV4_PARSER_KEYS.SIZEY)
        .uint16(HEADERV4_PARSER_KEYS.SIZEZ)
        .uint16(HEADERV4_PARSER_KEYS.SPAWNX)
        .uint16(HEADERV4_PARSER_KEYS.SPAWNY)
        .uint16(HEADERV4_PARSER_KEYS.SPAWNZ)
        .uint8(HEADERV4_PARSER_KEYS.SPAWNYAW)
        .uint8(HEADERV4_PARSER_KEYS.SPAWNPITCH)
        .uint32(HEADERV4_PARSER_KEYS.BLOCK_DATA_SIZE)
        .build();

enum BLOCK_PARSER_KEYS { BLOCK_ID, BLOCK_COUNT }

final BLOCK_PARSER =
    new DataParserBuilder<BLOCK_PARSER_KEYS>()
        .uint8(BLOCK_PARSER_KEYS.BLOCK_ID)
        .uint8(BLOCK_PARSER_KEYS.BLOCK_COUNT)
        .build();

enum VERSION_PARSER_KEYS { VERSION }

final VERSION_PARSER =
    new DataParserBuilder<VERSION_PARSER_KEYS>()
        .uint32(VERSION_PARSER_KEYS.VERSION)
        .build();

class HWorldFormat extends WorldFormat {
  HWorldFormat._privateConstructor();
  static final HWorldFormat _instance = HWorldFormat._privateConstructor();
  factory HWorldFormat() {
    return _instance;
  }
  List<String> get extensions => ['hworld'];
  @override
  bool identify(List<int> data) {
    return data.length > 10 &&
        AsciiDecoder().convert(data.sublist(5, 12)) == 'HWORLD';
  }

  WorldBuilder deserialize(List<int> data) {
    int version = VERSION_PARSER.decode(data)[VERSION_PARSER_KEYS.VERSION];
    int sizeX,
        sizeY,
        sizeZ,
        spawnX,
        spawnY,
        spawnZ,
        spawnYaw,
        spawnPitch,
        blockDataSize;
    if (version == 4) {
      final header = HEADERV4_PARSER.decode(data);
      sizeX = header[HEADERV4_PARSER_KEYS.SIZEX];
      sizeY = header[HEADERV4_PARSER_KEYS.SIZEY];
      sizeZ = header[HEADERV4_PARSER_KEYS.SIZEZ];
      spawnX = header[HEADERV4_PARSER_KEYS.SPAWNX];
      spawnY = header[HEADERV4_PARSER_KEYS.SPAWNY];
      spawnZ = header[HEADERV4_PARSER_KEYS.SPAWNZ];
      spawnYaw = header[HEADERV4_PARSER_KEYS.SPAWNYAW];
      spawnPitch = header[HEADERV4_PARSER_KEYS.SPAWNPITCH];
      blockDataSize = header[HEADERV4_PARSER_KEYS.BLOCK_DATA_SIZE];
    } else if (version >= 2 && version < 4) {
      final header = HEADERV2_PARSER.decode(data);
      sizeX = header[HEADERV2_PARSER_KEYS.SIZEX];
      sizeY = header[HEADERV2_PARSER_KEYS.SIZEY];
      sizeZ = header[HEADERV2_PARSER_KEYS.SIZEZ];
      spawnX = header[HEADERV2_PARSER_KEYS.SPAWNX];
      spawnY = header[HEADERV2_PARSER_KEYS.SPAWNY];
      spawnZ = header[HEADERV2_PARSER_KEYS.SPAWNZ];
      spawnYaw = header[HEADERV2_PARSER_KEYS.SPAWNYAW];
      spawnPitch = header[HEADERV2_PARSER_KEYS.SPAWNPITCH];
      blockDataSize = data.length - HEADERV2_PARSER.size!;
    } else {
      throw Exception('Unsupported version: $version');
    }
    var extractedBlocks = data.sublist(
      version == 4 ? HEADERV4_PARSER.size! : HEADERV2_PARSER.size!,
      version == 4 ? HEADERV4_PARSER.size! + blockDataSize : data.length,
    );
    if (version >= 3) {
      ZLibDecoder zlib = new ZLibDecoder();
      extractedBlocks = zlib.convert(extractedBlocks);
    }
    List<int> blocks = List.filled(sizeX * sizeY * sizeZ, 0);
    for (int i = 0; i < extractedBlocks.length; i += 3) {
      final block = BLOCK_PARSER.decode(extractedBlocks.sublist(i, i + 2));
      int id = block[BLOCK_PARSER_KEYS.BLOCK_ID];
      int count = block[BLOCK_PARSER_KEYS.BLOCK_COUNT];
      if (id == 0) {
        continue;
      }
      for (int j = 0; j < count; j++) {
        blocks[i + j] = id;
      }
    }
    return WorldBuilder(
      name: null,
      size: Vector3I(sizeX, sizeY, sizeZ),
      spawnPoint: EntityPosition(spawnX, spawnY, spawnZ, spawnYaw, spawnPitch),
      blocks: blocks,
    );
  }

  List<int> serialize(World world) {
    List<int> data = [];
    int? id, count;
    List<int> blocks = [];
    for (int i = 0; i < world.blocks.length; i++) {
      if (world.blocks[i] == id && id != null && count != null) {
        count++;
      } else {
        if (count != null && count > 0) {
          blocks.addAll(
            BLOCK_PARSER.encode({
              BLOCK_PARSER_KEYS.BLOCK_ID: id,
              BLOCK_PARSER_KEYS.BLOCK_COUNT: count,
            }),
          );
        }
        id = world.blocks[i];
        count = 1;
      }
    }
    if (count != null && count > 0) {
      blocks.addAll(
        BLOCK_PARSER.encode({
          BLOCK_PARSER_KEYS.BLOCK_ID: id,
          BLOCK_PARSER_KEYS.BLOCK_COUNT: count,
        }),
      );
    }
    ZLibEncoder zlib = new ZLibEncoder();
    List<int> compressedBlocks = zlib.convert(blocks);
    data.addAll(
      HEADERV4_PARSER.encode({
        HEADERV4_PARSER_KEYS.VERSION: 4,
        HEADERV4_PARSER_KEYS.IDENTIFIER: 'HWORLD',
        HEADERV4_PARSER_KEYS.SIZEX: world.size.x,
        HEADERV4_PARSER_KEYS.SIZEY: world.size.y,
        HEADERV4_PARSER_KEYS.SIZEZ: world.size.z,
        HEADERV4_PARSER_KEYS.SPAWNX: world.spawnPoint.x,
        HEADERV4_PARSER_KEYS.SPAWNY: world.spawnPoint.y,
        HEADERV4_PARSER_KEYS.SPAWNZ: world.spawnPoint.z,
        HEADERV4_PARSER_KEYS.SPAWNYAW: world.spawnPoint.yaw,
        HEADERV4_PARSER_KEYS.SPAWNPITCH: world.spawnPoint.pitch,
        HEADERV4_PARSER_KEYS.BLOCK_DATA_SIZE: compressedBlocks.length,
      }),
    );
    data.addAll(compressedBlocks);
    return data;
  }
}

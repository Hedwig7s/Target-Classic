import 'dart:io';
import 'dart:typed_data';

import 'package:events_emitter/events_emitter.dart';

import 'block.dart';
import 'datatypes.dart';
import 'entity.dart';
import 'networking/protocols/7/packetdata.dart';
import 'registries/namedregistry.dart';
import 'worldformats/hworld.dart';
import 'worldformats/worldformat.dart';
import 'package:path/path.dart' as p;

final WORLD_FORMATS = <WorldFormat>[HWorldFormat()];

class WorldBuilder {
  String? name;
  Vector3I? size;
  EntityPosition? spawnPoint;
  List<int>? blocks;

  WorldBuilder({this.name, this.size, this.spawnPoint, this.blocks});

  World build() {
    if (name == null || size == null || spawnPoint == null) {
      throw ArgumentError('World name, size, and spawn point must be provided');
    }
    return World(
      name: name!,
      size: size!,
      spawnPoint: spawnPoint!,
      blocks: blocks,
    );
  }
}

int calculateBlockIndex(Vector3I pos, Vector3I size) {
  if (pos.x < 0 ||
      pos.y < 0 ||
      pos.z < 0 ||
      pos.x >= size.x ||
      pos.y >= size.y ||
      pos.z >= size.z) {
    throw RangeError('Position $pos is out of bounds for size $size');
  }
  return pos.x + pos.z * size.x + pos.y * size.x * size.z;
}

class World implements Nameable<String> {
  final String name;
  final Vector3I size;
  final EntityPosition spawnPoint;
  final Map<int, Entity> entities = {};
  final List<int> blocks;
  final EventEmitter emitter = EventEmitter();

  World({
    required this.size,
    required this.spawnPoint,
    required this.name,
    blocks,
  }) : this.blocks = blocks ?? List.filled(size.x * size.y * size.z, 0) {
    // Initialize the world with the given size and spawn point
  }

  static Future<World> fromFile(String filePath, WorldFormat? format) async {
    filePath = p.join(Directory.current.path, p.normalize(filePath));
    File file = File(filePath);
    if (!(await file.exists())) {
      throw FileSystemException('File not found', filePath);
    }
    List<int> data = await file.readAsBytes();
    String extension = filePath.split('.').last.toLowerCase();
    if (format == null) {
      for (WorldFormat f in WORLD_FORMATS) {
        if (f.identify(data)) {
          format = f;
          break;
        } else if (f.extensions.contains(extension)) {
          if (format != null) {
            throw Exception(
              'Multiple formats found for file via extension: $filePath',
            );
          }
          format = f;
        }
      }
    }
    if (format == null) {
      throw Exception('No suitable format found for file: $filePath');
    }
    WorldBuilder builder = format.deserialize(data);
    if (builder.name == null) {
      builder.name = file.uri.pathSegments.last.split('.').first;
    }
    return builder.build();
  }

  // TODO: Replace with world generators
  factory World.superflat(String name, Vector3I size) {
    EntityPosition spawnPoint = EntityPosition(
      size.x / 2,
      size.y / 2,
      size.z / 2,
      0,
      0,
    );
    List<int> blocks = List.filled(size.x * size.y * size.z, 0);
    for (int x = 0; x < size.x; x++) {
      for (int y = 0; y < size.y; y++) {
        for (int z = 0; z < size.z; z++) {
          int index = calculateBlockIndex(Vector3I(x, y, z), size);
          if (y < 60) {
            blocks[index] = BlockID.stone.index;
          } else if (y <= 62) {
            blocks[index] = BlockID.dirt.index;
          } else if (y == 63) {
            blocks[index] = BlockID.grass.index;
          }
        }
      }
    }
    return World(
      name: name,
      size: size,
      spawnPoint: spawnPoint,
      blocks: blocks,
    );
  }

  Iterable<LevelDataChunkPacketData> getNetworkChunks() sync* {
    late final List<int> compressedData;
    {
      List<int> data = [];
      ByteData lengthData = ByteData(4)
        ..setUint32(0, blocks.length, Endian.big);
      data.addAll(lengthData.buffer.asUint8List());
      data.addAll(blocks);
      compressedData = GZipCodec().encoder.convert(data);
      data.clear();
    }
    int chunkSize = 1024;
    int totalChunks = (compressedData.length / chunkSize).ceil();
    for (int i = 0; i < totalChunks; i++) {
      int start = i * chunkSize;
      int end = (i + 1) * chunkSize;
      if (end > compressedData.length) {
        end = compressedData.length;
      }

      List<int> chunkData = compressedData.sublist(start, end);
      yield LevelDataChunkPacketData(
        chunkLength: chunkData.length,
        chunkData: chunkData,
        percentComplete: ((i + 1) / totalChunks * 100).toInt(),
      );
    }
  }

  int getBlockIndex(Vector3I pos) {
    return calculateBlockIndex(pos, size);
  }

  int getBlock(Vector3I pos) {
    int index = getBlockIndex(pos);
    if (index < 0 || index >= blocks.length) {
      throw RangeError('Index $index is out of bounds for blocks array');
    }
    return blocks[index];
  }

  void setBlock(Vector3I pos, BlockID block) {
    int index = getBlockIndex(pos);
    if (index < 0 || index >= blocks.length) {
      throw RangeError('Index $index is out of bounds for blocks array');
    }
    blocks[index] = block.index;
    emitter.emit('setBlock', (position: pos, block: block));
  }

  void addEntity(Entity entity) {
    int? id;
    for (int i = 0; i <= 255; i++) {
      if (!entities.containsKey(i)) {
        id = i;
        break;
      }
    }
    if (id == null) {
      throw Exception('No available ID for entity');
    }
    entities[id] = entity;
    entity.world = this;
    entity.worldId = id;
    emitter.emit('entityAdded', entity);
  }

  void removeEntity(Entity entity) {
    if (entity.worldId == null ||
        entity.world == null ||
        entity.world != this ||
        !entities.containsKey(entity.worldId)) {
      throw Exception('Entity is not in this world');
    }
    entities.remove(entity.worldId);
    entity.worldId = null;
    entity.world = null;
    emitter.emit('entityRemoved', entity);
  }
}

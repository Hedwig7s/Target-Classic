import 'dart:io';

import 'datatypes.dart';
import 'entity.dart';
import 'registries/namedregistry.dart';
import 'worldformats/hworld.dart';
import 'worldformats/worldformat.dart';

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

class World implements Nameable<String> {
  final String name;
  final Vector3I size;
  final EntityPosition spawnPoint;
  final Map<int, Entity> entities = {};
  final List<int> blocks;

  World({
    required this.size,
    required this.spawnPoint,
    required this.name,
    blocks,
  }) : this.blocks = blocks ?? List.filled(size.x * size.y * size.z, 0) {
    // Initialize the world with the given size and spawn point
  }

  static Future<World> fromFile(String filePath, WorldFormat? format) async {
    File file = File(filePath);
    if (!await file.exists()) {
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

  int getBlockIndex(Vector3I pos) {
    return blocks[pos.x + pos.z * size.x + pos.y * size.x * size.z];
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
  }
}

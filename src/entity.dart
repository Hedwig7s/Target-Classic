import 'datatypes.dart';
import 'registries/incrementalregistry.dart';
import 'world.dart';

class Entity implements IRRegisterable {
  EntityPosition position = EntityPosition(0, 0, 0, 0, 0);
  World? world;
  final Map<IncrementalRegistry, int> ids = {};
  final String name;
  final String fancyName;
  int? worldId;

  Entity({required this.name, fancyName}) : fancyName = fancyName ?? name;

  spawn(World world) {
    this.world = world;
    world.addEntity(this);
  }
}

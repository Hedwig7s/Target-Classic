import 'package:eventify/eventify.dart';

import 'datatypes.dart';
import 'registries/incrementalregistry.dart';
import 'world.dart';

class Entity implements IRRegisterable {
  EntityPosition _position = EntityPosition(0, 0, 0, 0, 0);
  EntityPosition get position => _position;
  World? world;
  final Map<IncrementalRegistry, int> ids = {};
  final String name;
  final String fancyName;
  int? worldId;
  final emitter = EventEmitter();

  Entity({required this.name, fancyName}) : fancyName = fancyName ?? name;

  spawn(World world) {
    if (this.world != null) {
      this.world!.removeEntity(this);
    }
    this.world = world;
    world.addEntity(this);
    emitter.emit('spawn', this);
  }

  move(EntityPosition newPosition) {
    _position = newPosition;
    emitter.emit('move', this, newPosition);
  }
}

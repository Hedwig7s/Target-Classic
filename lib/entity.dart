import 'package:events_emitter/events_emitter.dart';
import 'package:logging/logging.dart';
import 'package:target_classic/context.dart';

import 'package:target_classic/datatypes.dart';
import 'package:target_classic/networking/connection.dart';
import 'package:target_classic/registries/incrementalregistry.dart';
import 'package:target_classic/utility/clearemitter.dart';
import 'package:target_classic/world.dart';

abstract class Entity implements IRRegisterable {
  EntityPosition _position = EntityPosition(0, 0, 0, 0, 0);
  EntityPosition get position => _position;
  World? world;
  @override
  final Map<IncrementalRegistry, int> ids = {};
  final String name;
  final String fancyName;
  @override
  final emitter = EventEmitter();
  final Logger logger;
  final ServerContext? context;
  bool destroyed = false;
  int? worldId;

  Entity({required this.name, fancyName, this.context})
    : logger = Logger("Entity $name"),
      fancyName = fancyName ?? name {
    context?.registries.entityRegistry.register(this);
  }

  void spawn(World world) {
    if (this.world != null) {
      despawn();
    }
    this.world = world;
    world.addEntity(this);
    _position = world.spawnPoint;
    emitter.emit('spawned');
  }

  void move(EntityPosition newPosition) {
    _position = newPosition;
    emitter.emit('moved', newPosition);
  }

  void despawn() {
    world?.removeEntity(this);
    emitter.emit("despawn");
  }

  void destroy() {
    if (world != null) {
      despawn();
    }
    emitter.emit('destroyed');
    clearEmitter(emitter);
  }

  spawnFor(Connection connection);
}

import 'entity.dart';
import 'networking/connection.dart';
import 'registries/namedregistry.dart';
import 'registries/serviceregistry.dart';
import 'world.dart';

class Player implements Nameable<String> {
  String name;
  String fancyName;
  Connection connection;
  ServiceRegistry? serviceRegistry;
  Entity? entity;
  String get id => name;

  Player({
    required this.name,
    required this.fancyName,
    required this.connection,
    this.serviceRegistry,
    defaultEntity = true,
    entity,
  }) : assert(
         (entity == null) || (entity != null && defaultEntity == false),
         'Cannot set entity and defaultEntity at the same time',
       ) {
    if (defaultEntity) {
      entity = Entity(name: name, fancyName: fancyName);
    }
    this.entity = entity;
  }

  void loadWorld(World world) async {}
}

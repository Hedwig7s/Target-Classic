import 'datatypes.dart';
import 'registries/incrementalregistry.dart';
import 'registries/worldregistry.dart';

class Entity implements IRRegisterable {
  EntityPosition position = EntityPosition(0, 0, 0, 0, 0);
  Map<IncrementalRegistry, int> ids = {};
  final String name;
  final String fancyName;
  final Map<NamedRegistryWithDefault, int> worldIds = {};

  Entity({required this.name, fancyName}) : fancyName = fancyName ?? name;
}

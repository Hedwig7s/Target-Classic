import 'package:meta/meta.dart';

import 'namedregistry.dart';

class NamedRegistryWithDefault<K, V extends Nameable<K>>
    extends NamedRegistry<K, V> {
  @protected
  V? defaultItemP;
  V? get defaultItem => defaultItemP;
  setDefaultItem(V? item) {
    V? registeredWorld = registry[item?.name];
    if (registeredWorld != item && item != null) {
      register(item); // Duplicate will be detected here
    }
    defaultItemP = item;
    emitter.emit('setDefaultItem', item);
  }
}

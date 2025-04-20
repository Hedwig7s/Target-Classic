import 'namedregistry.dart';

class NamedRegistryWithDefault<K, V extends Nameable<K>>
    extends NamedRegistry<K, V> {
  V? _defaultItem;
  V? get defaultItem => _defaultItem;
  setDefaultItem(V? item) {
    V? registeredWorld = registry[item?.name];
    if (registeredWorld != item && item != null) {
      register(item); // Duplicate will be detected here
    }
    _defaultItem = item;
  }
}

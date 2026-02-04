import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:target_classic/registries/namedregistry.dart';

mixin DefaultItem<K, V extends Nameable<K>> on NamedRegistry<K, V> {
  @protected
  V? _default;
  V? get defaultValue => _default;
  set defaultValue(V? value) {
    V? registeredValue = registry[value?.name];
    if (registeredValue != value && value != null) {
      register(value); // Duplicate will be detected here
    }
    _default = value;
    emitter.emit('setDefault', value);
  }
}

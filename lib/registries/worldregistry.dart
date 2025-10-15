import 'dart:async';

import 'package:meta/meta.dart';
import '../world.dart';

import 'namedregistry.dart';

class WorldRegistry extends NamedRegistry<String, World> {
  @protected
  World? _defaultWorld;
  World? get defaultWorld => _defaultWorld;
  void setDefaultWorld(World? item) {
    World? registeredWorld = registry[item?.name];
    if (registeredWorld != item && item != null) {
      register(item); // Duplicate will be detected here
    }
    _defaultWorld = item;
    emitter.emit('setDefaultWorld', item);
  }

  bool shouldAutosave;
  final Duration autosaveInterval;

  WorldRegistry({
    this.shouldAutosave = true,
    this.autosaveInterval = const Duration(seconds: 30),
  }) {
    Timer.periodic(autosaveInterval, (timer) async {
      if (!shouldAutosave) return;
      List<Future<void>> futures = [];
      for (World world in registry.values) {
        futures.add(world.save());
      }
      for (var future in futures) {
        await future;
      }
    });
  }
}

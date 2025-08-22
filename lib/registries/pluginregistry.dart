import 'package:target_classic/plugins/plugin.dart';

class PluginRegistry {
  final Map<String, Plugin> plugins = {};
  void register(
    Plugin plugin, {
    bool startup = false,
    bool ignoreAutoLoad = false,
  }) {
    if (plugins.containsKey(plugin.name))
      throw ArgumentError("Cannot register 2 plugins by the same name");

    plugins[plugin.name] = plugin;
    if (plugin.autoLoad && !ignoreAutoLoad && !plugin.loaded) {
      plugin.load(startup);
    }
  }

  void unregister(
    Plugin plugin, {
    bool shutdown = false,
    bool autoUnload = true,
  }) {
    if (!plugins.containsKey(plugin.name))
      throw ArgumentError("Plugin not registered");
    if (plugins[plugin.name] != plugin)
      throw ArgumentError("Different plugin by same name registered");
    if (plugin.loaded && autoUnload) {
      plugin.unload(shutdown);
    }
  }
}

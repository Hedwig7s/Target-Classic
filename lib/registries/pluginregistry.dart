import 'dart:io';

import 'package:logging/logging.dart';
import 'package:target_classic/plugins/loaders/pluginloader.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart'
    deferred as luaPlugin;
import 'package:target_classic/plugins/plugin.dart';
import 'package:path/path.dart' as p;

class PluginRegistry {
  final Map<String, Plugin> plugins = {};
  static final Logger logger = Logger("PluginRegistry");
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

  Future<void> loadFromFile(String filePath) async {
    filePath = p.absolute(filePath);
    late final PluginLoader loader;
    var extension = p.extension(filePath);
    switch (extension) {
      /*case ".lua":
        {
          
          await luaPlugin.loadLibrary();
          loader = luaPlugin.LuaPluginLoader(filePath);
          break;
        }*/
      default:
        {
          logger.warning("Unrecognised plugin file: ${p.basename(filePath)}");
          return;
        }
    }
    try {
      //  loader.load(); // TODO: Actually make it create a plugin
    } catch (e, s) {
      logger.warning(
        "Failed to load loader for extension $extension\nError: $e\n$s",
      );
    }
  }

  Future<void> loadAllInDir(String dirPath) async {
    await (Directory(dirPath).list()).forEach((entry) async {
      if (entry is Directory) return;
      await loadFromFile(entry.path);
    });
  }
}

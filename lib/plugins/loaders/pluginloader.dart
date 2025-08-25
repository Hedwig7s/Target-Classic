import 'package:target_classic/plugins/plugin.dart';

abstract class PluginLoader {
  Plugin? get plugin;
  load();
  //Plugin reload();
  //void unload();
}

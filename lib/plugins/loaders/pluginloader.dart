import 'package:target_classic/plugins/plugin.dart';

abstract class PluginLoader {
  Plugin? get plugin;
  bool get loaded;
  
  load();
  //Plugin reload();
  //void unload();
}

abstract class Plugin {
  String get name;
  String get description;
  int get version;
  int get apiVersion;
  bool autoLoad = true;
  bool loaded = false;
  void load(bool startup);
  void unload(bool shutdown);
}

class DynamicPlugin extends Plugin {
  @override
  final String name;
  @override
  final String description;
  @override
  final int version;
  @override
  final int apiVersion;
  @override
  final bool autoLoad;
  final Function(Plugin) _load;
  final Function(Plugin) _unload;

  DynamicPlugin({
    required this.name,
    required this.description,
    required this.version,
    required this.apiVersion,
    this.autoLoad = true,
    required Function(Plugin) onLoad,
    required Function(Plugin) onUnload,
  }) : _load = onLoad,
       _unload = onUnload;
  @override
  void load(bool startup) {
    _load(this);
  }

  @override
  void unload(bool shutdown) {
    _unload(this);
  }
}

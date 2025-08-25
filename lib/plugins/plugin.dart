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
  final String name;
  final String description;
  final int version;
  final int apiVersion;
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
    this._load(this);
  }

  @override
  void unload(bool shutdown) {
    this._unload(this);
  }
}

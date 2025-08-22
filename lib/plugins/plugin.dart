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

abstract class DynamicPlugin {
  String name;
  String description;
  int version;
  bool autoLoad;
  DynamicPlugin({
    required this.name,
    required this.description,
    required this.version,
    this.autoLoad = true,
  });
}

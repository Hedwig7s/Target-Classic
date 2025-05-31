import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:toml/toml.dart';
import 'package:target_classic/constants.dart';

part 'serverconfig.freezed.dart';
part 'serverconfig.g.dart';

@freezed
abstract class ServerConfig with _$ServerConfig {
  static const String CONFIG_NAME = "server.toml";
  const factory ServerConfig([
    // Only for breaking changes needing adapting e.g. renaming a key
    @Default(1) final int version,
    @Default("0.0.0.0") final String host,
    @Default(25565) final int port,
    @Default("world") final String defaultWorld,
    @Default("Target-Classic") final String serverName,
    @Default("A classic server in dart") final String motd,
    @Default(false) final bool public,
    @Default(16) final int maxPlayers,
    @Default(false) final bool useRelativeMovements,
    @Default("https://www.classicube.net/server/heartbeat")
    final String heartbeatUrl,
  ]) = _ServerConfig;
  factory ServerConfig.fromJson(Map<String, dynamic> json) =>
      _$ServerConfigFromJson(json);
  static Future<ServerConfig> loadFromFile([String? path]) async {
    path ??= p.join(CONFIG_FOLDER, CONFIG_NAME);
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('File not found', path);
    }
    final content = await file.readAsString();
    return ServerConfig.fromToml(content);
  }

  static ServerConfig fromToml(String toml) {
    return ServerConfig.fromJson(TomlDocument.parse(toml).toMap());
  }
}

extension ServerConfigExtension on ServerConfig {
  String toToml() {
    return TomlDocument.fromMap(toJson()).toString();
  }

  Future<void> saveToFile([String? path]) async {
    path ??= p.join(CONFIG_FOLDER, ServerConfig.CONFIG_NAME);
    final file = File(path);
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    await file.writeAsString(toToml());
  }
}

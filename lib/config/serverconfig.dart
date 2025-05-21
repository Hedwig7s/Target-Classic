import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json5/json5.dart';
import 'package:path/path.dart' as p;
import '../constants.dart';

part 'serverconfig.freezed.dart';
part 'serverconfig.g.dart';

@freezed
abstract class ServerConfig with _$ServerConfig {
  static const String CONFIG_NAME = "server.json5";
  const factory ServerConfig([
    @Default("0.0.0.0") final String host,
    @Default(25565) final int port,
    @Default("world") final String defaultWorld,
    @Default("Target-Classic") final String serverName,
    @Default("A classic server in dart") final String motd,
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
    return ServerConfig.fromJson5(content);
  }

  static ServerConfig fromJson5(String json) {
    return ServerConfig.fromJson(JSON5.parse(json));
  }
}

extension ServerConfigExtension on ServerConfig {
  String toJson5() {
    return JSON5.stringify(toJson());
  }

  Future<void> saveToFile([String? path]) async {
    path ??= p.join(CONFIG_FOLDER, ServerConfig.CONFIG_NAME);
    final file = File(path);
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    await file.writeAsString(toJson5());
  }
}

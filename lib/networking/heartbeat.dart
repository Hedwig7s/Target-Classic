import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:target_classic/config/serverconfig.dart';
import 'package:target_classic/constants.dart';
import 'package:target_classic/context.dart';

const String defaultCachePath = "cachedsalt.txt";

class SaltManager {
  final String cachePath;
  Timer? _saltSaver;
  late final String _salt;
  static final Logger _logger = Logger("SaltManager");

  static bool isValidSaltChar(int byte) {
    return (byte >= 48 && byte <= 57) || // 0-9
        (byte >= 65 && byte <= 90) || // A-Z
        (byte >= 97 && byte <= 122); // a-z
  }

  static bool isValidSalt(String salt) {
    if (salt.length > 256) {
      return false;
    }
    for (int i = 0; i < salt.length; i++) {
      int byte = salt.codeUnitAt(i);
      if (!isValidSaltChar(byte)) {
        return false;
      }
    }
    return true;
  }

  static bool verifyNameWithSalt(String name, String key, String salt) =>
      (md5.convert(ascii.encode(salt + name))).toString() == key.toLowerCase();

  bool verifyName(String name, String key) {
    return verifyNameWithSalt(name, key, _salt);
  }

  static String generateSalt([int length = 32]) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) {
      while (true) {
        int byte = random.nextInt(256 - 48) + 48;
        if (!isValidSaltChar(byte)) {
          continue;
        } else
          return byte;
      }
    });
    return ascii.decode(bytes);
  }

  SaltManager({this.cachePath = defaultCachePath, String? salt}) {
    if (salt != null) {
      if (!isValidSalt(salt)) {
        throw Exception("Invalid salt provided");
      }
      _salt = salt;
    } else {
      _salt = generateSalt();
    }
  }

  static Future<SaltManager> fromFile({
    String cachePath = defaultCachePath,
  }) async {
    String salt = await readSalt(cachePath: cachePath) ?? generateSalt();
    return SaltManager(cachePath: cachePath, salt: salt);
  }

  static Future<SaltManager> tryFromFile({
    String cachePath = defaultCachePath,
  }) async {
    try {
      return await fromFile(cachePath: cachePath);
    } catch (e, stackTrace) {
      _logger.warning(
        "Failed to read salt from file, generating new one.\n$e\n$stackTrace",
      );
      return SaltManager(cachePath: cachePath);
    }
  }

  String get salt => _salt;

  Future<void> cacheSalt() async {
    if (_salt.contains("\n")) {
      throw Exception(
        "Salt may not contain newline", // Newline seperates the salt and timestamp
      );
    }
    var out = File(cachePath);
    await out.writeAsString(
      "$_salt\n${DateTime.now().toUtc().toIso8601String()}",
    );
  }

  static Future<String?> readSalt({cachePath = defaultCachePath}) async {
    List<String> data = await File(cachePath).readAsLines();
    if (data.length != 2) throw Exception("Invalid salt file");
    String salt = data[0];
    if (!isValidSalt(salt)) {
      throw Exception("Invalid salt in cache file");
    }
    String timestamp = data[1];
    if (DateTime.now().toUtc().difference(DateTime.parse(timestamp)).inMinutes >
        5)
      return null;
    return salt;
  }

  static Future<String> readOrGenerateSalt({
    int length = 32,
    cachePath = defaultCachePath,
  }) async {
    if (await File(cachePath).exists()) {
      try {
        String? readSaltValue = await readSalt();
        if (readSaltValue != null) {
          return readSaltValue;
        }
      } catch (e, stackTrace) {
        _logger.warning(
          "Failed to read cached salt, generating new one.\n$e\n$stackTrace",
        );
      }
    }
    String salt = generateSalt(length);
    return salt;
  }

  void startSaltSaver() {
    _saltSaver?.cancel();
    cacheSalt(); // Cache immediately on start
    _saltSaver = Timer(Duration(minutes: 1), () {
      cacheSalt();
    });
  }

  void stopSaltSaver() {
    _saltSaver?.cancel();
    _saltSaver = null;
  }
}

class HeartbeatInfo {
  String name;
  String salt;
  int port;
  int users;
  int max;
  bool public;
  String software;
  HeartbeatInfo({
    required this.name,
    required this.salt,
    required this.port,
    required this.users,
    required this.public,
    required this.software,
    required this.max,
  }) : assert(name.length <= 64, 'Server name must be 64 characters or less'),
       assert(salt.length <= 256, 'Salt must be 256 characters or less');

  String toParams() {
    return 'name=$name&salt=$salt&port=$port&users=$users&max=$max&public=$public&software=$software';
  }
}

class Heartbeat {
  final String heartbeatUrl;
  final Duration interval = Duration(seconds: 10);
  final Logger logger = Logger("Heartbeat");
  String? gameUrl;
  bool active = false;
  Timer? _timer;
  ServerConfig serverConfig;
  PlayerRegistry playerRegistry;
  SaltManager saltManager;
  String get salt => saltManager.salt;

  Heartbeat({
    this.heartbeatUrl = "https://www.classicube.net/server/heartbeat",
    required this.serverConfig,
    required String salt,
    required this.playerRegistry,
  }) : saltManager = SaltManager(salt: salt);

  Future<void> send(HeartbeatInfo info) async {
    // Unchanged
  }

  void start() {
    active = true;
    saltManager.startSaltSaver();
    final callback = (Timer timer) async {
      if (!active) {
        timer.cancel();
        return;
      }
      HeartbeatInfo info = HeartbeatInfo(
        name: serverConfig.serverName,
        salt: saltManager.salt,
        port: serverConfig.port,
        users: playerRegistry.length,
        max: serverConfig.maxPlayers,
        public: serverConfig.public,
        software: "$SOFTWARE_NAME $SOFTWARE_VERSION",
      );
      await send(info);
    };
    _timer = Timer.periodic(interval, callback);
    callback.call(_timer!);
  }

  void stop() {
    active = false;
    saltManager.stopSaltSaver();
    _timer?.cancel();
    _timer = null;
  }
}

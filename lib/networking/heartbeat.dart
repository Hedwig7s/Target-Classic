import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:target_classic/config/serverconfig.dart';
import 'package:target_classic/constants.dart';
import 'package:target_classic/context.dart';

String generateSalt([int length = 32]) {
  final random = Random.secure();
  final bytes = List<int>.generate(length, (_) => random.nextInt(256));
  return base64Url.encode(bytes);
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
  final String salt;
  final Duration interval = Duration(seconds: 10);
  final Logger logger = Logger("Heartbeat");
  String? gameUrl;
  bool active = false;
  Timer? _timer;
  ServerConfig serverConfig;
  PlayerRegistry playerRegistry;

  Heartbeat({
    this.heartbeatUrl = "https://www.classicube.net/server/heartbeat",
    required this.serverConfig,
    required this.salt,
    required this.playerRegistry,
  });
  Future<void> send(HeartbeatInfo info) async {
    try {
      final request = await HttpClient().getUrl(
        Uri.parse(
          Uri.encodeFull(
            heartbeatUrl.replaceAll(RegExp(r"\/$"), "") +
                "/?${info.toParams()}",
          ),
        ),
      );
      final response = await request.close();
      if (response.statusCode != 200) {
        logger.warning(
          "Failed to send heartbeat: ${response.statusCode} ${response.reasonPhrase}",
        );
        return;
      }
      response.transform(utf8.decoder).listen((data) {
        if (data.startsWith("{")) {
          var jsonResponse = json.decode(data);
          if (jsonResponse['status'] == "fail")
            logger.warning(
              "Failed to send heartbeat: ${jsonResponse['errors']}",
            );
        } else if (gameUrl != data) {
          gameUrl = data;
          logger.info("Game URL updated: $gameUrl");
        }
      });
    } catch (e) {
      logger.warning('Error sending heartbeat: $e');
    }
  }

  void start() {
    active = true;
    final callback = (Timer timer) async {
      if (!active) {
        timer.cancel();
        return;
      }
      // Replace with actual heartbeat info
      HeartbeatInfo info = HeartbeatInfo(
        name: serverConfig.serverName,
        salt: salt,
        port: serverConfig.port,
        users: playerRegistry.getAll().length,
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
    _timer?.cancel();
    _timer = null;
  }
}

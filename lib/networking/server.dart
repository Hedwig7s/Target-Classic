import 'dart:async';
import 'dart:io';

import 'package:events_emitter/events_emitter.dart';
import 'package:logging/logging.dart';
import 'package:target_classic/cooldown.dart';
import '../context.dart';

import 'connection.dart';

class Server {
  final String host;
  final int port;
  final Map<int, Connection> connections = {};
  final EventEmitter emitter = EventEmitter();
  final Logger logger = Logger("Server");
  final Map<String, Cooldown> cooldowns = {};
  int connectionsEver = 0;
  ServerSocket? socket;
  ServerContext? context;
  bool closed = false;

  Server(this.host, this.port, {this.context}) {
    if (host.isEmpty) {
      throw ArgumentError('Host cannot be empty');
    }
    if (port <= 0 || port > 65535) {
      throw ArgumentError('Port must be between 1 and 65535');
    }
  }
  void start() async {
    socket = await ServerSocket.bind(host, port);
    socket!.listen(
      (Socket socket) {
        if (closed) {
          logger.warning("Server is closed, rejecting connection");
          socket.close();
          return;
        }
        String address = socket.remoteAddress.address;
        logger.info('Connection from $address:${socket.remotePort}');
        Cooldown? cooldown = cooldowns[address];
        if (cooldown != null && !cooldown.canUse()) {
          logger.warning('Connection from $address is on cooldown');
          socket.close();
          return;
        } else if (cooldown == null) {
          cooldown = Cooldown(maxCount: 5, resetTime: Duration(seconds: 20));
          cooldowns[address] = cooldown;
        }
        int id = connectionsEver++;
        Connection connection = Connection(id, socket, context: context);
        connections[id] = connection;
        emitter.emit("connectionOpened", connection);
        connection.emitter.on("closed", (data) {
          emitter.emit("connectionClosed", connection);
        });
      },
      onError: (error) {
        logger.severe('Error: $error');
      },
      onDone: () {
        logger.info('Server stopped');
      },
    );
    Timer.periodic(Duration(minutes: 1), (timer) {
      if (closed) {
        timer.cancel();
        return;
      }
      cooldowns.removeWhere(
        (key, value) => value.lastReset.isBefore(
          DateTime.now().subtract(Duration(minutes: 5)),
        ),
      );
    });
  }

  Future<void> stop() async {
    if (closed) {
      logger.warning("Server is already stopped");
      return;
    }
    closed = true;
    logger.info("Stopping...");
    for (var connection in connections.values) {
      connection.close("Server is stopping", Duration(milliseconds: 50));
    }
    await Future.delayed(Duration(milliseconds: 50));
    await socket?.close();
    connections.clear();
    emitter.emit("serverStopped");
    cooldowns.clear();
  }
}

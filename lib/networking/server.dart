import 'dart:io';

import 'package:events_emitter/events_emitter.dart';
import 'package:logging/logging.dart';

import 'connection.dart';
import '../registries/instanceregistry.dart';

class Server {
  final String host;
  final int port;
  final Map<int, Connection> connections = {};
  final EventEmitter emitter = EventEmitter();
  final Logger logger = Logger("Server");
  int connectionsEver = 0;
  ServerSocket? socket;
  InstanceRegistry? instanceRegistry;
  bool closed = false;

  Server(this.host, this.port, {this.instanceRegistry}) {
    if (host.isEmpty) {
      throw ArgumentError('Host cannot be empty');
    }
    if (port <= 0 || port > 65535) {
      throw ArgumentError('Port must be between 1 and 65535');
    }
  }
  void start() async {
    this.socket = await ServerSocket.bind(this.host, this.port);
    this.socket!.listen(
      (Socket socket) {
        if (closed) {
          logger.warning("Server is closed, rejecting connection");
          socket.close();
          return;
        }
        logger.info(
          'Connection from ${socket.remoteAddress.address}:${socket.remotePort}',
        );
        int id = connectionsEver++;
        Connection connection = Connection(
          id,
          socket,
          instanceRegistry: instanceRegistry,
        );
        connections[id] = connection;
        emitter.emit("connectionOpened", connection);
        connection.emitter.on("closed", (data) {
          this.emitter.emit("connectionClosed", connection);
        });
      },
      onError: (error) {
        logger.severe('Error: $error');
      },
      onDone: () {
        logger.info('Server stopped');
      },
    );
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
    logger.info("Server stopped");
  }
}

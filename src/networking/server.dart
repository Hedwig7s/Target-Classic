import 'dart:io';
import 'connection.dart';
import '../registries/serviceregistry.dart';

class Server {
  final String host;
  final int port;
  final Map<int, Connection> connections = {};
  int connectionsEver = 0;
  ServerSocket? socket;
  ServiceRegistry? serviceRegistry;

  Server(this.host, this.port, {this.serviceRegistry}) {
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
        print(
          'Connection from ${socket.remoteAddress.address}:${socket.remotePort}',
        );
        int id = connectionsEver++;
        Connection connection = Connection(id, socket);
        connections[id] = connection;
      },
      onError: (error) {
        print('Error: $error');
      },
      onDone: () {
        print('Server stopped');
      },
    );
  }
}

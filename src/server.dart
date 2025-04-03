import 'dart:io';
import 'connection.dart';

class Server {
  final String host;
  final int port;
  final List<Connection> connections = [];
  int connectionsEver = 0;
  ServerSocket? socket;

  Server(this.host, this.port) {
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
        socket.listen(
          (data) {
            print('Received data: ${String.fromCharCodes(data)}');
            socket.write('Echo: ${String.fromCharCodes(data)}');
          },
          onDone: () {
            print('Client disconnected');
            socket.close();
          },
          onError: (error) {
            print('Error: $error');
          },
        );
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

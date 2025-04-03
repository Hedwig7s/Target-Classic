import 'src/server.dart';

void main() {
  Server server = new Server("0.0.0.0", 25564);
  server.start();
  print("Server started on ${server.host}:${server.port}");
}

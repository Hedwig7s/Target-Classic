import 'src/networking/server.dart';
import 'src/registries/registryextras.dart';
import 'src/registries/serviceregistry.dart';

void main() async {
  ServiceRegistry serviceRegistry = await getServerServiceRegistry();
  Server server = serviceRegistry.getService<Server>("server");
  server.start();
  print("Server started on ${server.host}:${server.port}");
}

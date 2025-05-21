import 'lib/networking/server.dart';
import 'lib/registries/registryextras.dart';
import 'lib/registries/instanceregistry.dart';

void main() async {
  InstanceRegistry instanceRegistry = await getServerInstanceRegistry();
  Server server = instanceRegistry.getInstance<Server>("server");
  server.start();
  print("Server started on ${server.host}:${server.port}");
}

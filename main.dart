import 'lib/networking/server.dart';
import 'lib/registries/registryextras.dart';
import 'lib/registries/instanceregistry.dart';
import 'package:logging/logging.dart';

void main() async {
  final colors = {
    Level.FINE: "\x1b[30;1m",
    Level.INFO: "\x1b[37m",
    Level.WARNING: "\x1b[33m",
    Level.SEVERE: "\x1b[31m",
  };
  Logger.root.onRecord.listen((record) {
    // TODO: Save logs
    String message =
        "[${record.time.hour.toString().padLeft(2, "0")}:${record.time.minute.toString().padLeft(2, "0")}:${record.time.second.toString().padLeft(2, "0")}] [${record.loggerName.isEmpty ? "Main" : record.loggerName}/${record.level.name}]: ${record.message}";
    print("${colors[record.level] ?? ""}$message${"\x1b[0m"}");
  });
  InstanceRegistry instanceRegistry = await getServerInstanceRegistry();
  Server server = instanceRegistry.getInstance<Server>("server");
  server.start();
  Logger.root.info("Server started on ${server.host}:${server.port}");
}

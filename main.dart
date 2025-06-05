import 'dart:io';

import 'package:dotenv/dotenv.dart';

import 'package:target_classic/networking/server.dart';
import 'package:target_classic/context.dart';
import 'package:logging/logging.dart';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  Logger.root.level = Level.LEVELS.firstWhere(
    (level) => level.name.toLowerCase() == env['LOG_LEVEL']?.toLowerCase(),
    orElse: () => Level.INFO,
  );
  final colors = {
    Level.FINEST: "\x1b[30;2m",
    Level.FINER: "\x1b[30;2m",
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
  ServerContext context = await ServerContext.defaultContext();
  Server server = context.server!;
  server.start();
  Logger.root.info("Server started on ${server.host}:${server.port}");
  context.heartbeat?.start();
  print(context.heartbeat?.salt);
  context.heartbeat?.startSaltSaver();
  int caughtInterrupts = 0;
  ProcessSignal.sigint.watch().listen((signal) async {
    caughtInterrupts++;
    if (caughtInterrupts == 2) {
      Logger.root.warning("Force exiting now.");
      exit(1);
    }
    Logger.root.info(
      "Server shutting down...",
    ); // TODO: If commands are implemented, move shutdown to a seperate function
    await server.stop();
    var worlds = context.worldRegistry?.getAll();
    if (worlds != null) {
      for (var world in worlds) {
        world.save();
      }
    }
    Logger.root.info("Server shutdown complete.");
    exit(0);
  });
}

import 'dart:async';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:target_classic/commands/builtin/registerbuiltin.dart';
import 'package:target_classic/cooldown.dart';

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
  Map<String, Cooldown> logCooldowns = {};
  Logger.root.onRecord.listen((record) {
    String recordMessage = record.message;
    Cooldown? logCooldown = logCooldowns[recordMessage];
    if (!(logCooldown?.canUse() ?? true)) {
      return;
    } else if (logCooldown == null) {
      logCooldowns[recordMessage] = Cooldown(
        maxCount: 1,
        resetTime: const Duration(milliseconds: 500),
      );
    }
    // TODO: Save logs
    String message =
        "[${record.time.hour.toString().padLeft(2, "0")}:${record.time.minute.toString().padLeft(2, "0")}:${record.time.second.toString().padLeft(2, "0")}] [${record.loggerName.isEmpty ? "Main" : record.loggerName}/${record.level.name}]: $recordMessage";
    print("${colors[record.level] ?? ""}$message${"\x1b[0m"}");
  });
  Timer.periodic(const Duration(seconds: 5), (timer) {
    logCooldowns.removeWhere(
      (_, value) =>
          DateTime.now().difference(value.lastReset) >= Duration(seconds: 1),
    );
  });
  ServerContext context = await ServerContext.defaultContext();
  registerBuiltinCommands(context);
  Server server = context.server!;
  server.start();
  Logger.root.info("Server started on ${server.host}:${server.port}");
  context.heartbeat?.start();
  context.heartbeat?.saltManager.startSaltSaver();
  int caughtInterrupts = 0;
  ProcessSignal.sigint.watch().listen((signal) async {
    // TODO: Unload plugins
    caughtInterrupts++;
    if (caughtInterrupts == 2) {
      Logger.root.warning("Force exiting now.");
      exit(1);
    }
    Logger.root.info(
      "Server shutting down...",
    ); // TODO: If commands are implemented, move shutdown to a seperate function
    await server.stop();
    var worlds = context.registries.worldRegistry.getAll();
    var futures = <Future>[];
    for (var world in worlds) {
      futures.add(world.save());
    }
    for (var future in futures) {
      await future;
    }
    if (context.heartbeat?.saltManager != null) {
      context.heartbeat!.saltManager.stopSaltSaver();
      await context.heartbeat!.saltManager.cacheSalt();
    }
    context.heartbeat?.stop();
    Logger.root.info("Server shutdown complete.");
    exit(0);
  });
}

import 'dart:async';
import 'dart:io';

import 'package:events_emitter/emitters/event_emitter.dart';
import 'package:logging/logging.dart';
import 'package:target_classic/context.dart';
import 'package:target_classic/cooldown.dart';
import 'package:target_classic/networking/packetdata.dart';
import 'package:target_classic/utility/clearemitter.dart';

import 'package:target_classic/constants.dart';
import 'package:target_classic/player.dart';
import 'package:target_classic/networking/packet.dart';
import 'package:target_classic/networking/protocol.dart';

class DataCooldown {
  int _dataReceived = 0;
  int get dataReceived => _dataReceived;
  DateTime _lastReset = DateTime.fromMicrosecondsSinceEpoch(0);
  DateTime get lastReset => _lastReset;
  final Duration resetTime;
  final int maxData;

  DataCooldown({
    this.maxData = 10000,
    this.resetTime = const Duration(seconds: 5),
  });

  bool canUse(int dataSize) {
    if (_lastReset.add(resetTime).isBefore(DateTime.now())) {
      _dataReceived = 0;
      _lastReset = DateTime.now();
    }
    _dataReceived += dataSize;
    if (_dataReceived < 0) {
      _dataReceived =
          0x7FFFFFFFFFFFFFFF; // Reset to max value if overflow occurs (unlikely but you never know)
    }
    return _dataReceived <= maxData;
  }
}

class Connection {
  final int id;
  final Socket socket;
  final Logger logger;
  List<int> buffer = [];
  bool closed = false;
  bool socketClosed = false;
  bool processingIncoming = false;
  Protocol? protocol;
  ServerContext? context;
  Player? player;
  EventEmitter emitter = EventEmitter();
  DataCooldown dataCooldown = DataCooldown();
  Cooldown packetCooldown;
  int packetCount = 0;

  Connection(this.id, this.socket, {this.context, Cooldown? packetCooldown})
    : logger = Logger("Connection $id"),
      packetCooldown =
          packetCooldown ??
          Cooldown(maxCount: 60, resetTime: const Duration(seconds: 1)) {
    socket.listen(
      (data) {
        if (closed) {
          logger.warning('Connection $id is closed, ignoring incoming data');
          return;
        }
        if (!dataCooldown.canUse(data.length)) {
          logger.warning('Data limit exceeded, closing connection $id');
          close("Received too much data in a short time");
          return;
        }
        buffer.addAll(data);
        processIncoming();
      },
      onDone: () {
        logger.info('Client disconnected');
        socketClosed = true;
        if (closed) return;
        close();
      },
      onError: (error) {
        onError(error);
      },
    );
  }
  void processIncoming() async {
    if (processingIncoming) return;
    processingIncoming = true;
    try {
      while (buffer.isNotEmpty) {
        int id = buffer[0];
        if (id < 0 || id >= PacketIds.values.length) {
          logger.warning('Invalid packet id: $id');
          close();
          return;
        }
        PacketIds packetId = PacketIds.values[id];
        if (protocol == null && packetId != PacketIds.identification) {
          logger.warning('Protocol not set, closing connection');
          close();
          return;
        }
        if (protocol == null && packetId == PacketIds.identification) {
          if (buffer.length < 2) {
            logger.fine('Buffer too small for identification packet');
            return;
          }
          int protocolVersion = buffer[1];
          Protocol? protocol = protocols[protocolVersion];
          if (protocol == null) {
            logger.warning('Invalid protocol version: $protocolVersion');
            close();
            return;
          }
          this.protocol = protocol;
        }
        Packet? packet = protocol!.packets[packetId];
        if (packet == null) {
          logger.warning('Invalid packet id: $packetId');
          close("Invalid packet: Unknown packet id: $packetId");
          return;
        }
        if (!packetCooldown.canUse()) {
          logger.warning("Too many packets!");
          close("Too many packets!");
        }
        if (buffer.length < packet.length) {
          break; // Not enough data for the packet
        }
        List<int> packetData = buffer.sublist(0, packet.length);
        buffer = buffer.sublist(packet.length);
        if (packet is! ReceivablePacket) {
          logger.warning('Packet is not receivable: $packet');
          close(
            "Invalid packet: Packet $id cannot be sent to the server.",
          );
          return;
        }
        ReceivablePacket receivablePacket = packet;
        await receivablePacket.receive(this, packetData);
      }
    } catch (e, stackTrace) {
      logger.warning('Error processing incoming data\n$e\n$stackTrace');
      close("Internal error while processing incoming data.");
    } finally {
      processingIncoming = false;
    }
  }

  void write(List<int> data, {bool force = false}) {
    if ((closed && !force) || (force && socketClosed)) return;
    try {
      socket.add(data);
    } catch (e, stackTrace) {
      logger.severe("Failed to write into socket", e, stackTrace);
    }
  }

  void onError(error) {
    logger.warning('Error: $error');
    if (closed) return;
    close("An internal error occurred");
  }

  Future<void>? close([
    String? reason,
    Duration receiveReasonDelay = const Duration(milliseconds: 50),
  ]) {
    try {
      if (closed) return null;
      logger.info('Closing connection $id${reason != null ? ': $reason' : ''}');
      closed = true;
      player?.disconnect("Connection closed");
      if (reason != null && !socketClosed && protocol != null) {
        var disconnectPacket = protocol
            ?.getPacket<SendablePacket<DisconnectPlayerPacketData>>(
              PacketIds.disconnectPlayer,
            );
        if (disconnectPacket != null) {
          disconnectPacket.send(
            this,
            DisconnectPlayerPacketData(reason: reason),
          );
        } else {
          logger.warning("Disconnect packet not found");
        }
        // Give client time to process disconnect
        return Future.delayed(receiveReasonDelay, () {
          emitter.emit("closed");
          if (socketClosed) return;
          socket.destroy();
        });
      }
      emitter.emit("closed");
      clearEmitter(emitter);
      if (socketClosed) return null;
      socket.destroy();
    } catch (e, stackTrace) {
      print(e);
      logger.warning("Error closing connection: $e\n$stackTrace");
      try {
        socket.destroy();
      } catch (ignored) {}
    }
    return null;
  }
}

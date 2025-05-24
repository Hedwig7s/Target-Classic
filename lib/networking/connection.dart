import 'dart:io';

import 'package:events_emitter/emitters/event_emitter.dart';
import 'package:logging/logging.dart';
import 'packetdata.dart';
import '../utility/clearemitter.dart';

import '../constants.dart';
import '../player.dart';
import 'packet.dart';
import 'protocol.dart';
import '../registries/instanceregistry.dart';

class Connection {
  final int id;
  final Socket socket;
  final Logger logger;
  List<int> buffer = [];
  bool closed = false;
  bool socketClosed = false;
  bool processingIncoming = false;
  Protocol? protocol;
  InstanceRegistry? instanceRegistry;
  Player? player;
  EventEmitter emitter = EventEmitter();

  Connection(this.id, this.socket, {this.instanceRegistry})
    : logger = Logger("Connection $id") {
    socket.listen(
      (data) {
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
        this.onError(error);
      },
    );
  }

  void processIncoming() async {
    if (processingIncoming) return;
    processingIncoming = true;
    try {
      while (buffer.length > 0) {
        int id = buffer[0];
        if (id < 0 || id >= PacketIds.values.length) {
          logger.warning('Invalid packet id: $id');
          this.close();
          return;
        }
        PacketIds packetId = PacketIds.values[id];
        if (protocol == null && packetId != PacketIds.identification) {
          logger.warning('Protocol not set, closing connection');
          this.close();
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
            this.close();
            return;
          }
          this.protocol = protocol;
        }
        Packet? packet = protocol!.packets[packetId];
        if (packet == null) {
          logger.warning('Invalid packet id: $packetId');
          this.close("Invalid packet: Unknown packet id: $packetId");
          return;
        }
        if (buffer.length < packet.length) {
          break; // Not enough data for the packet
        }
        List<int> packetData = buffer.sublist(0, packet.length);
        buffer = buffer.sublist(packet.length);
        if (packet is! ReceivablePacket) {
          logger.warning('Packet is not receivable: $packet');
          this.close(
            "Invalid packet: Packet ${id} cannot be sent to the server.",
          );
          return;
        }
        ReceivablePacket receivablePacket = packet;
        await receivablePacket.receive(this, packetData);
      }
    } catch (e, stackTrace) {
      logger.warning('Error processing incoming data: $e\n$stackTrace');
      this.close("Internal error while processing incoming data.");
    } finally {
      processingIncoming = false;
    }
  }

  write(List<int> data, {bool force = false}) {
    if (closed && (!force && !socketClosed)) return;
    socket.add(data);
  }

  onError(error) {
    logger.warning('Error: $error');
    if (closed) return;
    this.close("An internal error occurred");
  }

  close([
    String? reason = null,
    Duration receiveReasonDelay = const Duration(milliseconds: 100),
  ]) {
    try {
      if (closed) return;
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
        Future.delayed(receiveReasonDelay, () {
          if (socketClosed) return;
          socket.destroy();
        });
        return;
      }
      emitter.emit("closed");
      clearEmitter(emitter);
      if (socketClosed) return;
      socket.destroy();
    } catch (e) {
      logger.warning('Error closing connection: $e');
      try {
        socket.destroy();
      } catch (ignored) {}
    }
  }
}

import 'dart:io';

import '../constants.dart';
import 'packet.dart';
import 'protocol.dart';
import '../registries/serviceregistry.dart';

class Connection {
  final int id;
  final Socket socket;
  List<int> buffer = [];
  bool closed = false;
  bool socketClosed = false;
  bool processingIncoming = false;
  Protocol? protocol;
  ServiceRegistry? serviceRegistry;

  Connection(this.id, this.socket, {this.serviceRegistry}) {
    socket.listen(
      (data) {
        buffer.addAll(data);
        processIncoming();
      },
      onDone: () {
        print('Client disconnected');
        socketClosed = true;
        if (closed) return;
        socket.close();
      },
      onError: (error) {
        this.onError(error);
      },
    );
  }

  void processIncoming() async {
    if (processingIncoming) return;
    while (buffer.length > 0) {
      int id = buffer[0];
      if (id < 0 || id >= PacketIds.values.length) {
        print('Invalid packet id: $id');
        this.close();
        return;
      }
      PacketIds packetId = PacketIds.values[id];
      if (protocol == null && packetId != PacketIds.identification) {
        print('Protocol not set, closing connection');
        this.close();
        return;
      }
      if (protocol == null && packetId == PacketIds.identification) {
        if (buffer.length < 2) {
          print('Buffer too small for identification packet');
          return;
        }
        int protocolVersion = buffer[1];
        Protocol? protocol = protocols[protocolVersion];
        if (protocol == null) {
          print('Invalid protocol version: $protocolVersion');
          this.close();
          return;
        }
        this.protocol = protocol;
      }
      Packet? packet = protocol!.packets[packetId];
      if (packet == null) {
        print('Invalid packet id: $packetId');
        this.close();
        return;
      }
      if (buffer.length < packet.length) {
        break; // Not enough data for the packet
      }
      List<int> packetData = buffer.sublist(0, packet.length);
      buffer = buffer.sublist(packet.length);
      if (packet is! ReceivablePacket) {
        print('Packet is not receivable: $packet');
        this.close();
        return;
      }
      await packet.receive(this, packetData);
    }
    processingIncoming = false;
  }

  write(List<int> data) {
    if (closed) return;
    socket.add(data);
  }

  onError(error) {
    print('Error: $error');
    if (closed) return;
    socket.close();
  }

  close() {
    if (closed) return;
    closed = true;
    if (socketClosed) return;
    print('Closing connection $id');
    socket.close();
  }
}

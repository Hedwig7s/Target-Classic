import 'packetdata.dart';
import 'connection.dart';

abstract class Packet {
  int get id;
  int get length;
}

mixin SendablePacket<DataType extends PacketData> on Packet {
  List<int> encode(DataType data);
  void send(Connection connection, DataType data) async {
    if (connection.closed) return;
    var encodedData = encode(data);
    connection.write(encodedData);
  }
}

mixin ReceivablePacket<DataType extends PacketData> on Packet {
  DataType decode(List<int> data);
  Future<void> receive(Connection connection, List<int> data);
}

import 'dataparser/parser.dart';

abstract class Packet<KeyEnum extends Enum> {
  int get id;
  int get length;
  DataParser<KeyEnum> get parser;
  int? get size => parser.size;
}

mixin SendablePacket<KeyEnum extends Enum> on Packet<KeyEnum> {
  List<int> encode(Map<KeyEnum, dynamic> data) {
    return parser.encode(data);
  }

  void send() async {
    // TODO: Implement send logic
  }
}

mixin ReceivablePacket<KeyEnum extends Enum> on Packet<KeyEnum> {
  Map<KeyEnum, dynamic> decode(List<int> data) {
    return parser.decode(data);
  }

  void receive() async {
    // TODO: Implement receive logic
  }
}

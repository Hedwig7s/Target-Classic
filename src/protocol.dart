import 'dart:typed_data';

import 'packet.dart';

abstract class Protocol {
  int get version;
  Map<int, Packet> get packets;
  bool identify(Uint8List data) {
    if (data.length < 2) {
      return false;
    }
    return data[1] == version;
  }
}

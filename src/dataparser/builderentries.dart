import 'dart:convert';
import 'dart:typed_data';
import 'package:buffer/buffer.dart';

abstract class DataParserEntry<Key> {
  final Key key;
  final int? size = 0;

  DataParserEntry({required this.key});

  void decode(ByteDataReader data, Endian endianness, Map<Key, dynamic> out);

  void encode(Map<Key, dynamic> data, Endian endianness, ByteDataWriter out);
}

class EntryInt<Key> extends DataParserEntry<Key> {
  final int size;
  final bool signed;

  EntryInt({required Key key, required this.size, required this.signed})
    : super(key: key);

  @override
  void decode(ByteDataReader data, Endian endianness, Map<Key, dynamic> out) {
    int value =
        this.signed
            ? data.readInt(this.size, endianness)
            : data.readUint(this.size, endianness);
    out[key] = value;
  }

  @override
  void encode(Map<Key, dynamic> data, Endian endianness, ByteDataWriter out) {
    if (data[key] is! int) {
      throw ArgumentError('Value for key $key must be an integer');
    }
    int value = data[key];
    if (this.signed) {
      out.writeInt(size, value, endianness);
    } else {
      out.writeUint(size, value, endianness);
    }
  }
}

class EntryFixedString<Key> extends DataParserEntry<Key> {
  final int size;
  final Encoding encoding;
  final String? padding;
  EntryFixedString({
    required Key key,
    required this.size,
    required this.encoding,
    this.padding,
  }) : super(key: key);

  @override
  void decode(ByteDataReader data, Endian endianness, Map<Key, dynamic> out) {
    var decoder = encoding.decoder;
    String value = decoder.convert(data.read(size));
    if (padding != null &&
        padding!.isNotEmpty &&
        value.length > 0 &&
        value.endsWith(padding!)) {
      int paddingEnd = value.length;
      for (int i = 0; i < padding!.length; i++) {
        if (value[i] != padding!) {
          paddingEnd = i;
          break;
        }
      }
      value = value.substring(0, paddingEnd);
    }
    out[key] = value;
  }

  @override
  void encode(Map<Key, dynamic> data, Endian endianness, ByteDataWriter out) {
    if (data[key] is! String) {
      throw ArgumentError('Value for key $key must be a String');
    }
    String value = data[key];
    if (value.length > size) {
      throw ArgumentError('String is too long');
    }
    var encoder = encoding.encoder;
    List<int> bytes = List.from(encoder.convert(value));

    if (bytes.length < size) {
      if (padding != null && padding!.isNotEmpty) {
        List<int> paddingBytes = encoder.convert(padding!);
        while (bytes.length < size) {
          bytes.addAll(paddingBytes);
        }
        if (bytes.length > size) {
          bytes = bytes.sublist(0, size);
        }
      } else {
        throw ArgumentError('String is too short and no padding is defined');
      }
    }

    if (bytes.length > size) {
      throw ArgumentError('Encoded string is too long');
    }
    out.write(bytes);
  }
}

class EntryTerminatedString<Key> extends DataParserEntry<Key> {
  final Encoding encoding;
  final int terminator;
  final int? size = null;
  EntryTerminatedString({
    required Key key,
    required this.encoding,
    int? terminator,
  }) : this.terminator = terminator ?? 0,
       super(key: key);

  @override
  void decode(ByteDataReader data, Endian endianness, Map<Key, dynamic> out) {
    var decoder = encoding.decoder;
    String value = decoder.convert(data.readUntilTerminatingByte(terminator));
    out[key] = value;
  }

  @override
  void encode(Map<Key, dynamic> data, Endian endianness, ByteDataWriter out) {
    if (data[key] is! String) {
      throw ArgumentError('Value for key $key must be a String');
    }
    var encoder = encoding.encoder;
    List<int> value = List.from(encoder.convert(data[key]));
    value.add(this.terminator);
    out.write(value);
  }
}

class EntryLengthPrefixedString<Key> extends DataParserEntry<Key> {
  final Encoding encoding;
  final int intSize;
  final bool signed;
  final int? size = null;

  EntryLengthPrefixedString({
    required Key key,
    required this.encoding,
    required this.intSize,
    bool? signed,
  }) : this.signed = signed ?? false,
       super(key: key);
  @override
  void decode(ByteDataReader data, Endian endianness, Map<Key, dynamic> out) {
    int length =
        signed
            ? data.readInt(intSize, endianness)
            : data.readUint(intSize, endianness);
    if (length < 0) {
      throw ArgumentError('Length is negative');
    }
    var decoder = encoding.decoder;
    String value = decoder.convert(data.read(length));
    out[key] = value;
  }

  @override
  void encode(Map<Key, dynamic> data, Endian endianness, ByteDataWriter out) {
    if (data[key] is! String) {
      throw ArgumentError('Value for key $key must be a String');
    }
    var encoder = encoding.encoder;
    List<int> value = encoder.convert(data[key]);
    if (signed) {
      out.writeInt(intSize, value.length, endianness);
    } else {
      out.writeUint(intSize, value.length, endianness);
    }
    out.write(value);
  }
}

class EntryRaw<Key> extends DataParserEntry<Key> {
  final int size;

  EntryRaw({required Key key, required this.size}) : super(key: key);

  @override
  void decode(ByteDataReader data, Endian endianness, Map<Key, dynamic> out) {
    List<int> value = data.read(size);
    out[key] = value;
  }

  @override
  void encode(Map<Key, dynamic> data, Endian endianness, ByteDataWriter out) {
    if (data[key] is! List<int> && data[key] is! Uint8List) {
      throw ArgumentError(
        'Value for key $key must be a List<int> or Uint8List',
      );
    }
    List<int> value = data[key];
    out.write(value);
  }
}

class EntryPadding<Key> extends DataParserEntry<Key> {
  final int size;
  final int padding;

  EntryPadding({required Key key, required this.size, this.padding = 0})
    : super(key: key);

  @override
  void decode(ByteDataReader data, Endian endianness, Map<Key, dynamic> out) {
    data.read(size);
  }

  @override
  void encode(Map<Key, dynamic> data, Endian endianness, ByteDataWriter out) {
    out.write(List.filled(size, this.padding));
  }
}

class EntryFloat<Key> extends DataParserEntry<Key> {
  final bool doublePrecision;
  final int size;
  EntryFloat({required Key key, this.doublePrecision = false})
    : this.size = doublePrecision ? 8 : 4,
      super(key: key);
  @override
  void decode(ByteDataReader data, Endian endianness, Map<Key, dynamic> out) {
    if (doublePrecision) {
      double value = data.readFloat64(endianness);
      out[key] = value;
    } else {
      double value = data.readFloat32(endianness);
      out[key] = value;
    }
  }

  @override
  void encode(Map<Key, dynamic> data, Endian endianness, ByteDataWriter out) {
    if (data[key] is! num) {
      throw ArgumentError('Value for key $key must be a numeric value');
    }
    if (doublePrecision) {
      out.writeFloat64(data[key], endianness);
    } else {
      double value = data[key].toDouble();
      if (value > 3.4028234663852886e38 || value < -3.4028234663852886e38) {
        throw ArgumentError('Value is out of range for float32');
      }
      out.writeFloat32(value, endianness);
    }
  }
}

class EntryBool<Key> extends DataParserEntry<Key> {
  final int size;
  final bool signed;

  EntryBool({required Key key, required this.size, required this.signed})
    : super(key: key);

  @override
  void decode(ByteDataReader data, Endian endianness, Map<Key, dynamic> out) {
    int value =
        this.signed
            ? data.readInt(this.size, endianness)
            : data.readUint(this.size, endianness);
    out[key] = value != 0;
  }

  @override
  void encode(Map<Key, dynamic> data, Endian endianness, ByteDataWriter out) {
    if (data[key] is! bool) {
      throw ArgumentError('Value for key $key must be a boolean');
    }
    int value = data[key] ? 1 : 0;
    if (this.signed) {
      out.writeInt(size, value, endianness);
    } else {
      out.writeUint(size, value, endianness);
    }
  }
}

class EndiannessEntry<Key> extends DataParserEntry<Key> {
  final int size = 0;
  final Endian endianness;

  EndiannessEntry({required this.endianness}) : super(key: '' as Key);
  @override
  void decode(ByteDataReader data, Endian endianness, Map<Key, dynamic> out) {
    // No-op
  }
  @override
  void encode(Map<Key, dynamic> data, Endian endianness, ByteDataWriter out) {
    // No-op
  }
}

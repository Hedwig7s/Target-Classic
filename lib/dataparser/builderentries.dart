import 'dart:convert';
import 'dart:typed_data';
import 'package:buffer/buffer.dart';

abstract class DataParserEntry {
  final int? size = 0;

  DataParserEntry();

  void decode(ByteDataReader data, Endian endianness, List out);

  void encode(List data, int index, Endian endianness, ByteDataWriter out);
}

class EntryInt extends DataParserEntry {
  final int size;
  final bool signed;

  EntryInt({required this.size, required this.signed}) : super();

  @override
  void decode(ByteDataReader data, Endian endianness, List out) {
    int value =
        this.signed
            ? data.readInt(this.size, endianness)
            : data.readUint(this.size, endianness);
    out.add(value);
  }

  @override
  void encode(List data, int index, Endian endianness, ByteDataWriter out) {
    if (data[index] is! int) {
      throw ArgumentError('Value at index $index must be an integer');
    }
    int value = data[index];
    if (this.signed) {
      out.writeInt(size, value, endianness);
    } else {
      out.writeUint(size, value, endianness);
    }
  }
}

class EntryFixedString extends DataParserEntry {
  final int size;
  final Encoding encoding;
  final String? padding;
  EntryFixedString({required this.size, required this.encoding, this.padding})
    : super();

  @override
  void decode(ByteDataReader data, Endian endianness, List out) {
    var decoder = encoding.decoder;
    String value = decoder.convert(data.read(size));
    if (padding != null &&
        padding!.isNotEmpty &&
        value.length > 0 &&
        value.endsWith(padding!)) {
      int paddingEnd = value.length;
      for (
        int i = value.length - padding!.length;
        i > 0;
        i -= padding!.length
      ) {
        if (value.substring(i, i + padding!.length) != padding!) {
          paddingEnd = i + padding!.length;
          break;
        }
      }
      value = value.substring(0, paddingEnd);
    }
    out.add(value);
  }

  @override
  void encode(List data, int index, Endian endianness, ByteDataWriter out) {
    if (data[index] is! String) {
      throw ArgumentError('Value at index $index must be a String');
    }
    String value = data[index];
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

class EntryTerminatedString extends DataParserEntry {
  final Encoding encoding;
  final int terminator;
  final int? size = null;
  EntryTerminatedString({required this.encoding, int? terminator})
    : this.terminator = terminator ?? 0,
      super();

  @override
  void decode(ByteDataReader data, Endian endianness, List out) {
    var decoder = encoding.decoder;
    String value = decoder.convert(data.readUntilTerminatingByte(terminator));
    out.add(value);
  }

  @override
  void encode(List data, int index, Endian endianness, ByteDataWriter out) {
    if (data[index] is! String) {
      throw ArgumentError('Value at index $index must be a String');
    }
    var encoder = encoding.encoder;
    List<int> value = List.from(encoder.convert(data[index]));
    value.add(this.terminator);
    out.write(value);
  }
}

class EntryLengthPrefixedString extends DataParserEntry {
  final Encoding encoding;
  final int intSize;
  final bool signed;
  final int? size = null;

  EntryLengthPrefixedString({
    required this.encoding,
    required this.intSize,
    bool? signed,
  }) : this.signed = signed ?? false,
       super();
  @override
  void decode(ByteDataReader data, Endian endianness, List out) {
    int length =
        signed
            ? data.readInt(intSize, endianness)
            : data.readUint(intSize, endianness);
    if (length < 0) {
      throw ArgumentError('Length is negative');
    }
    var decoder = encoding.decoder;
    String value = decoder.convert(data.read(length));
    out.add(value);
  }

  @override
  void encode(List data, int index, Endian endianness, ByteDataWriter out) {
    if (data[index] is! String) {
      throw ArgumentError('Value at index $index must be a String');
    }
    var encoder = encoding.encoder;
    List<int> value = encoder.convert(data[index]);
    if (signed) {
      out.writeInt(intSize, value.length, endianness);
    } else {
      out.writeUint(intSize, value.length, endianness);
    }
    out.write(value);
  }
}

class EntryRaw extends DataParserEntry {
  final int size;
  final int padding;

  EntryRaw({required this.size, this.padding = 0}) : super();

  @override
  void decode(ByteDataReader data, Endian endianness, List out) {
    List<int> value = data.read(size);
    out.add(value);
  }

  @override
  void encode(List data, int index, Endian endianness, ByteDataWriter out) {
    if (data[index] is! List<int> && data[index] is! Uint8List) {
      throw ArgumentError(
        'Value at index $index must be a List<int> or Uint8List',
      );
    }
    List<int> value = data[index];
    if (value.length > size) {
      throw ArgumentError('Raw data is too long');
    }
    if (value.length < size) {
      List<int> newValue = List.filled(size, padding);
      newValue.setAll(0, value);
      value = newValue;
    }
    out.write(value);
  }
}

class EntryPadding extends DataParserEntry {
  final int size;
  final int padding;

  EntryPadding({required this.size, this.padding = 0}) : super();

  @override
  void decode(ByteDataReader data, Endian endianness, List out) {
    data.read(size);
    // No value to add to output
  }

  @override
  void encode(List data, int index, Endian endianness, ByteDataWriter out) {
    out.write(List.filled(size, this.padding));
  }
}

class EntryFloat extends DataParserEntry {
  final bool doublePrecision;
  final int size;
  EntryFloat({this.doublePrecision = false})
    : this.size = doublePrecision ? 8 : 4,
      super();
  @override
  void decode(ByteDataReader data, Endian endianness, List out) {
    if (doublePrecision) {
      double value = data.readFloat64(endianness);
      out.add(value);
    } else {
      double value = data.readFloat32(endianness);
      out.add(value);
    }
  }

  @override
  void encode(List data, int index, Endian endianness, ByteDataWriter out) {
    if (data[index] is! num) {
      throw ArgumentError('Value at index $index must be a numeric value');
    }
    if (doublePrecision) {
      out.writeFloat64(data[index], endianness);
    } else {
      double value = data[index].toDouble();
      if (value > 3.4028234663852886e38 || value < -3.4028234663852886e38) {
        throw ArgumentError('Value is out of range for float32');
      }
      out.writeFloat32(value, endianness);
    }
  }
}

class EntryBool extends DataParserEntry {
  final int size;
  final bool signed;

  EntryBool({required this.size, required this.signed}) : super();

  @override
  void decode(ByteDataReader data, Endian endianness, List out) {
    int value =
        this.signed
            ? data.readInt(this.size, endianness)
            : data.readUint(this.size, endianness);
    out.add(value != 0);
  }

  @override
  void encode(List data, int index, Endian endianness, ByteDataWriter out) {
    if (data[index] is! bool) {
      throw ArgumentError('Value at index $index must be a boolean');
    }
    int value = data[index] ? 1 : 0;
    if (this.signed) {
      out.writeInt(size, value, endianness);
    } else {
      out.writeUint(size, value, endianness);
    }
  }
}

class EntryFixedPoint extends DataParserEntry {
  final int size;
  final bool signed;
  final int fractionalBits;

  EntryFixedPoint({
    required this.size,
    required this.signed,
    required this.fractionalBits,
  }) : super();

  @override
  void decode(ByteDataReader data, Endian endianness, List out) {
    int rawValue = signed
        ? data.readInt(size, endianness)
        : data.readUint(size, endianness);
    double value = rawValue / (1 << fractionalBits);
    out.add(value);
  }

  @override
  void encode(List data, int index, Endian endianness, ByteDataWriter out) {
    if (data[index] is! num) {
      throw ArgumentError('Value at index $index must be a numeric type');
    }
    double scaled = (data[index] as num).toDouble() * (1 << fractionalBits);
    int intValue = scaled.round();
    if (signed) {
      out.writeInt(size, intValue, endianness);
    } else {
      if (intValue < 0) {
        throw ArgumentError('Fixed point value must be non-negative for unsigned entry');
      }
      out.writeUint(size, intValue, endianness);
    }
  }
}


class EndiannessEntry extends DataParserEntry {
  final int size = 0;
  final Endian endianness;

  EndiannessEntry({required this.endianness}) : super();
  @override
  void decode(ByteDataReader data, Endian endianness, List out) {
    // No-op
  }
  @override
  void encode(List data, int index, Endian endianness, ByteDataWriter out) {
    // No-op
  }
}

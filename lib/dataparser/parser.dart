import 'builderentries.dart';
import 'dart:typed_data';
import 'package:buffer/buffer.dart';

class DataParser<Key> {
  final List<DataParserEntry> _entries;
  int? size = 0; // If null, size is unknown/dynamic
  // If size is known, it will be the sum of all entry sizes
  Endian endianness = Endian.little;
  DataParser(entries) : _entries = List.unmodifiable(entries) {
    if (entries.isEmpty) {
      throw Exception("No entries provided to DataParser");
    }
    for (DataParserEntry entry in entries) {
      if (this.size != null && entry.size != null) {
        this.size = this.size! + entry.size!;
      } else if (entry.size == null) {
        size = null;
      }
    }
  }
  List<dynamic> decode(List<int> data) {
    List<dynamic> out = [];
    ByteDataReader byteDataReader = ByteDataReader();
    byteDataReader.add(data);
    for (var entry in _entries) {
      if (entry is EndiannessEntry) {
        endianness = entry.endianness;
      } else {
        try {
          /*print("${entry.key} ${entry.size} ${byteDataReader.remainingLength}");
          var start = byteDataReader.offsetInBytes;
          */
          entry.decode(byteDataReader, endianness, out);
          /*var end = byteDataReader.offsetInBytes;
          print("Consumed ${end - start} bytes for ${entry.key}");
          if (entry.size != null) {
            if (end - start != entry.size) {
              print(
                "Warning: Expected ${entry.size} bytes for ${entry.key}, but consumed ${end - start} bytes",
              );
            }
          }*/
        } catch (e, stackTrace) {
          Error.throwWithStackTrace(
            Exception("Error decoding entry ${out.length}: $e"),
            stackTrace,
          );
        }
      }
    }
    return out;
  }

  Future<List<dynamic>> decodeWaitOnData(
    ByteDataReader data, {
    Duration pollInterval = const Duration(milliseconds: 5),
    DateTime? timeout,
  }) async {
    List<dynamic> out = [];
    for (var entry in _entries) {
      if (entry is EndiannessEntry) {
        endianness = entry.endianness;
      } else {
        while (true) {
          try {
            entry.decode(data, endianness, out);
          } catch (e, stackTrace) {
            if (e.toString().contains("Not enough bytes")) {
              if (timeout != null && DateTime.now().isAfter(timeout)) {
                throw Exception(
                  "Timeout while waiting for data for entry ${out.length}",
                );
              }
              var remaining = data.remainingLength;
              await Future.doWhile(
                () => Future.delayed(pollInterval).then(
                  (_) =>
                      entry.size == null
                          ? data.remainingLength == remaining
                          : data.remainingLength < entry.size!,
                ),
              );
              continue;
            }
            Error.throwWithStackTrace(
              Exception("Error decoding entry ${out.length}: $e"),
              stackTrace,
            );
          }
          break;
        }
      }
    }
    return out;
  }

  List<int> encode(List<dynamic> data) {
    ByteDataWriter byteDataWriter = ByteDataWriter();
    int offset = 0;
    for (int i = 0; i < _entries.length; i++) {
      var entry = _entries[i];
      if (entry is EndiannessEntry) {
        endianness = entry.endianness;
      } else {
        try {
          entry.encode(data, offset++, endianness, byteDataWriter);
        } catch (e, stackTrace) {
          Error.throwWithStackTrace(
            Exception(
              "Error encoding entry ${entry.runtimeType.toString()} ${i}: $e",
            ),
            stackTrace,
          );
        }
      }
    }
    return byteDataWriter.toBytes();
  }
}

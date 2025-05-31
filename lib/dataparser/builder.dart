import 'package:target_classic/dataparser/builderentries.dart';
import 'package:target_classic/dataparser/parser.dart';
import 'dart:convert';
import 'dart:typed_data';

class DataParserBuilder {
  final List<DataParserEntry> _entries = [];

  void addEntry(DataParserEntry entry) {
    _entries.add(entry);
  }

  void removeEntry(DataParserEntry entry) {
    _entries.remove(entry);
  }

  List<DataParserEntry> get entries => List.unmodifiable(_entries);

  void clearEntries() {
    _entries.clear();
  }

  DataParser build() {
    return DataParser(_entries);
  }

  DataParserBuilder littleEndian() {
    addEntry(new EndiannessEntry(endianness: Endian.little));
    return this;
  }

  DataParserBuilder bigEndian() {
    addEntry(new EndiannessEntry(endianness: Endian.big));
    return this;
  }

  DataParserBuilder uint(int size) {
    addEntry(new EntryInt(size: size, signed: false));
    return this;
  }

  DataParserBuilder sint(int size) {
    addEntry(new EntryInt(size: size, signed: true));
    return this;
  }

  DataParserBuilder float32({bool doublePrecision = false}) {
    addEntry(new EntryFloat(doublePrecision: doublePrecision));
    return this;
  }

  DataParserBuilder float64() {
    addEntry(new EntryFloat(doublePrecision: true));
    return this;
  }

  DataParserBuilder boolean({bool signed = false, int size = 1}) {
    addEntry(new EntryBool(size: size, signed: signed));
    return this;
  }

  DataParserBuilder fixedString(
    int size,
    Encoding encoding, {
    String? padding,
  }) {
    addEntry(
      new EntryFixedString(size: size, encoding: encoding, padding: padding),
    );
    return this;
  }

  DataParserBuilder terminatedString(Encoding encoding, {int? terminator}) {
    addEntry(
      new EntryTerminatedString(encoding: encoding, terminator: terminator),
    );
    return this;
  }

  DataParserBuilder lengthPrefixedString(
    Encoding encoding,
    int intSize, {
    bool? signed,
  }) {
    addEntry(
      new EntryLengthPrefixedString(
        encoding: encoding,
        signed: signed,
        intSize: intSize,
      ),
    );
    return this;
  }

  DataParserBuilder fixedPoint({
    required int size,
    required int fractionalBits,
    bool signed = false,
  }) {
    addEntry(
      new EntryFixedPoint(
        size: size,
        fractionalBits: fractionalBits,
        signed: signed,
      ),
    );
    return this;
  }

  DataParserBuilder bytes(int size) {
    addEntry(new EntryRaw(size: size));
    return this;
  }

  DataParserBuilder padding(int size) {
    addEntry(new EntryPadding(size: size));
    return this;
  }

  DataParserBuilder uint8() {
    return uint(1);
  }

  DataParserBuilder uint16() {
    return uint(2);
  }

  DataParserBuilder uint32() {
    return uint(4);
  }

  DataParserBuilder uint64() {
    return uint(8);
  }

  DataParserBuilder sint8() {
    return sint(1);
  }

  DataParserBuilder sint16() {
    return sint(2);
  }

  DataParserBuilder sint32() {
    return sint(4);
  }

  DataParserBuilder sint64() {
    return sint(8);
  }
}

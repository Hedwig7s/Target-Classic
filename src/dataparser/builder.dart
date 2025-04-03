import 'builderentries.dart';
import 'parser.dart';
import 'dart:convert';
import 'dart:typed_data';

class DataParserBuilder<Key> {
  final List<DataParserEntry<Key>> _entries = [];

  void addEntry(DataParserEntry<Key> entry) {
    _entries.add(entry);
  }

  void removeEntry(DataParserEntry<Key> entry) {
    _entries.remove(entry);
  }

  List<DataParserEntry<Key>> get entries => List.unmodifiable(_entries);

  void clearEntries() {
    _entries.clear();
  }

  DataParser<Key> build() {
    return new DataParser<Key>(_entries);
  }

  DataParserBuilder<Key> littleEndian<key>() {
    addEntry(new EndiannessEntry<Key>(endianness: Endian.little));
    return this;
  }

  DataParserBuilder<Key> bigEndian<key>() {
    addEntry(new EndiannessEntry<Key>(endianness: Endian.big));
    return this;
  }

  DataParserBuilder uint(Key key, int size) {
    addEntry(new EntryInt(key: key, size: size, signed: false));
    return this;
  }

  DataParserBuilder sint(Key key, int size) {
    addEntry(new EntryInt(key: key, size: size, signed: true));
    return this;
  }

  DataParserBuilder float(Key key, {bool doublePrecision = false}) {
    addEntry(new EntryFloat(key: key, doublePrecision: doublePrecision));
    return this;
  }

  DataParserBuilder doubleFloat(Key key) {
    addEntry(new EntryFloat(key: key, doublePrecision: true));
    return this;
  }

  DataParserBuilder boolean(Key key, {bool signed = false, int size = 1}) {
    addEntry(new EntryBool(key: key, size: size, signed: signed));
    return this;
  }

  DataParserBuilder fixedString(
    Key key,
    int size,
    Encoding encoding, {
    String? padding,
  }) {
    addEntry(
      new EntryFixedString(
        key: key,
        size: size,
        encoding: encoding,
        padding: padding,
      ),
    );
    return this;
  }

  DataParserBuilder terminatedString(
    Key key,
    Encoding encoding, {
    int? terminator,
  }) {
    addEntry(
      new EntryTerminatedString(
        key: key,
        encoding: encoding,
        terminator: terminator,
      ),
    );
    return this;
  }

  DataParserBuilder lengthPrefixedString(
    Key key,
    Encoding encoding,
    int intSize, {
    bool? signed,
  }) {
    addEntry(
      new EntryLengthPrefixedString(
        key: key,
        encoding: encoding,
        signed: signed,
        intSize: intSize,
      ),
    );
    return this;
  }

  DataParserBuilder raw(Key key, int size) {
    addEntry(new EntryRaw(key: key, size: size));
    return this;
  }

  DataParserBuilder padding(Key key, int size) {
    addEntry(new EntryPadding(key: key, size: size));
    return this;
  }

  DataParserBuilder uint8(Key key) {
    return uint(key, 1);
  }

  DataParserBuilder uint16(Key key) {
    return uint(key, 2);
  }

  DataParserBuilder uint32(Key key) {
    return uint(key, 4);
  }

  DataParserBuilder uint64(Key key) {
    return uint(key, 8);
  }

  DataParserBuilder sint8(Key key) {
    return sint(key, 1);
  }

  DataParserBuilder sint16(Key key) {
    return sint(key, 2);
  }

  DataParserBuilder sint32(Key key) {
    return sint(key, 4);
  }

  DataParserBuilder sint64(Key key) {
    return sint(key, 8);
  }
}

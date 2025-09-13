import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

extension LuaPointer on String {
  Pointer<Char> toLuaPointer([Allocator allocator = malloc]) {
    return this.toNativeUtf8(allocator: allocator).cast();
  }

  int get utf8Length {
    return utf8.encode(this).length;
  }
}

String luaStringFromPointer(Pointer<Char> ptr, int length) {
  final bytes = ptr.cast<Uint8>().asTypedList(length);
  return utf8.decode(bytes);
}

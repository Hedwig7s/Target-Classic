import 'dart:convert';
import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:ffi/ffi.dart';

extension LuaPointer on String {
  Pointer<Char> toLuaPointer([Allocator allocator = malloc]) {
    return this.toNativeUtf8(allocator: allocator).cast();
  }

  LuaString toLuaString() {
    return LuaString.fromString(this);
  }

  int get utf8Length {
    return utf8.encode(this).length;
  }
}

class LuaString {
  static final ptrFinalizer = Finalizer<Pointer<luaL_Reg>>((ptr) {
    malloc.free(ptr);
  });

  late final Pointer<Char> ptr;
  late final String string;
  bool _freed = false;
  bool get freed => _freed;

  LuaString(this.ptr, this.string);

  LuaString.fromString(this.string) {
    this.ptr = this.string.toLuaPointer();
  }

  LuaString.fromPointer(Pointer<Char> ptr, int? length) {
    final utf8Str = ptr.cast<Utf8>();
    this.string = utf8Str.toDartString(length: length);
    final clone = malloc<Uint8>(
      utf8Str.length + 1,
    ); // TODO: Maybe split into seperate function cloning
    final bytes = utf8Str.cast<Uint8>();
    for (var i = 0; i <= utf8Str.length; i++) {
      clone[i] = bytes[i]; // Copy each byte including null terminator
    }
    this.ptr = clone.cast<Char>();
  }

  void free() {
    if (this._freed) return;
    this._freed = true;
    ptrFinalizer.detach(this);
    ptrFinalizer.detach(this);
  }
}

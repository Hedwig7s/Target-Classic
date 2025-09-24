import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

extension LuaPointer on String {
  Pointer<Char> toLuaPointer([Allocator allocator = malloc]) {
    return toNativeUtf8(allocator: allocator).cast();
  }

  LuaString toLuaString() {
    return LuaString.fromString(this);
  }

  int get utf8Length {
    return utf8.encode(this).length;
  }
}

class LuaString {
  static final ptrFinalizerCallback = (ptr) {
    malloc.free(ptr);
  };
  static final ptrFinalizer = Finalizer<Pointer<Char>>(ptrFinalizerCallback);

  late final Pointer<Char> ptr;
  late final String string;
  bool _freed = false;
  bool get freed => _freed;

  LuaString(this.ptr, this.string);

  LuaString.fromString(this.string) {
    ptr = string.toLuaPointer();
    ptrFinalizer.attach(this, ptr, detach: this);
  }

  LuaString.fromPointer(Pointer<Char> ptr, int? length) {
    final utf8Str = ptr.cast<Utf8>();
    string = utf8Str.toDartString(length: length);
    final clone = malloc<Uint8>(
      utf8Str.length + 1,
    ); // TODO: Maybe split into seperate function cloning
    final bytes = utf8Str.cast<Uint8>();
    for (var i = 0; i <= utf8Str.length; i++) {
      clone[i] = bytes[i]; // Copy each byte including null terminator
    }
    this.ptr = clone.cast<Char>();
    ptrFinalizer.attach(this, this.ptr, detach: this);
  }

  void free() {
    if (_freed) return;
    _freed = true;
    malloc.free(ptr);
    ptrFinalizer.detach(this);
  }
}

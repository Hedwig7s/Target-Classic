import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:ffi/ffi.dart';
import 'package:target_classic/plugins/loaders/lua/utility/luastrings.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/callables.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/types.dart';

typedef RegFunction = (String name, LuaCallback func);

class LuaReg {
  static final regFinalizer = Finalizer<Pointer<luaL_Reg>>((ptr) {
    calloc.free(ptr);
  });
  static final nameFinalizer = Finalizer<List<Pointer<Void>>>((names) {
    names.forEach((ptr) => calloc.free(ptr));
  });

  late final Pointer<luaL_Reg> ptr;
  late final List<Pointer<Char>> _names;
  bool _freed = false;

  LuaReg(this.ptr, this._names);

  LuaReg.createFromFunctions(List<RegFunction> functions) {
    this.ptr = calloc<luaL_Reg>(functions.length + 1);
    this._names = <Pointer<Char>>[];

    for (int i = 0; i < functions.length; i++) {
      final (name, func) = functions[i];
      final namePtr = name.toLuaPointer(calloc);
      _names.add(namePtr);
      var callable = getCallable(func);

      ptr[i]
        ..name = namePtr.cast()
        ..func = callable.nativeFunction;
    }

    ptr[functions.length]
      ..name = nullptr
      ..func = nullptr;
    regFinalizer.attach(this, ptr, detach: this);
  }

  void free() {
    if (this._freed) return;
    this._freed = true;
    regFinalizer.detach(this);
    nameFinalizer.detach(this);
  }
}

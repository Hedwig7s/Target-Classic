import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:ffi/ffi.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/callables.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luastring.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/types.dart';

typedef RegFunction = (String name, LuaCallback func);

class LuaReg {
  static final regFinalizerCallback = (ptr) {
    calloc.free(ptr);
  };
  static final regFinalizer = Finalizer<Pointer<luaL_Reg>>(
    regFinalizerCallback,
  );
  static final nameFinalizerCallback = (names) {
    names.forEach((name) => name.free());
  };
  static final nameFinalizer = Finalizer<List<LuaString>>(
    nameFinalizerCallback,
  );

  late final Pointer<luaL_Reg> ptr;
  late final List<LuaString> _names;
  bool _freed = false;
  bool get freed => _freed;

  LuaReg(this.ptr, this._names);

  LuaReg.fromFunctions(List<RegFunction> functions) {
    ptr = calloc<luaL_Reg>(functions.length + 1);
    _names = <LuaString>[];

    for (int i = 0; i < functions.length; i++) {
      final (name, func) = functions[i];
      final luaName = name.toLuaString();
      _names.add(luaName);
      var callable = getCallable(func);

      ptr[i]
        ..name = luaName.ptr
        ..func = callable.nativeFunction;
    }

    ptr[functions.length]
      ..name = nullptr
      ..func = nullptr;
    regFinalizer.attach(this, ptr, detach: this);
  }

  void free() {
    if (_freed) return;
    _freed = true;
    regFinalizer.detach(this);
    nameFinalizer.detach(this);
    regFinalizerCallback(ptr);
    nameFinalizerCallback(_names);
  }
}

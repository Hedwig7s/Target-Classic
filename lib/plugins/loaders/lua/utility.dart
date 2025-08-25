import 'dart:convert';
import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';

extension LuaPointer on String {
  Pointer<Char> toLuaPointer([Allocator allocator = malloc]) {
    return this.toNativeUtf8(allocator: allocator).cast();
  }
}

int luaError(Pointer<lua_State> luaState, String error) {
  var luaerr = error.toLuaPointer();
  try {
    lua.lua_pushstring(luaState, luaerr);
  } finally {
    malloc.free(luaerr);
  }
  return lua.lua_error(luaState);
}

int dartErrorToLua(
  Pointer<lua_State> luaState,
  Object error,
  StackTrace stackTrace, [
  bool dontLog = false,
]) {
  if (!dontLog)
    Logger.root.log(
      Level.WARNING,
      "Error forwarded to lua: $error",
      stackTrace,
    );
  return luaError(luaState, "Dart Error: $error\n$stackTrace");
}

String luaStringFromPointer(Pointer<Char> ptr, int length) {
  final bytes = ptr.cast<Uint8>().asTypedList(length);
  return utf8.decode(bytes);
}

typedef LuaCallback = int Function(Pointer<lua_State>);

typedef MetatableFunction = (String name, LuaCallback func);
final callables = <NativeCallable<Int Function(Pointer<lua_State>)>>[];

void createMetatable(
  Pointer<lua_State> luaState,
  String name,
  List<MetatableFunction> functions, [
  bool setIndexToSelf = false,
]) {
  final reg = calloc<luaL_Reg>(functions.length + 1);
  try {
    using((arena) {
      var metaname = name.toLuaPointer(arena);
      lua.luaL_newmetatable(luaState, metaname);
      for (int i = 0; i < functions.length; i++) {
        final (name, func) = functions[i];
        final callable =
            NativeCallable<Int Function(Pointer<lua_State>)>.isolateLocal(
              func,
              exceptionalReturn: 1,
            );
        callables.add(callable);
        var luaName = name.toLuaPointer(arena);
        reg[i].name = luaName;
        reg[i].func = callable.nativeFunction;
      }

      reg[functions.length].name = nullptr.cast();
      reg[functions.length].func = nullptr.cast();

      lua.luaL_setfuncs(luaState, reg, 0);
      if (setIndexToSelf) {
        lua.lua_pushvalue(luaState, -1); // copy metatable
        lua.lua_setfield(luaState, -2, "__index".toLuaPointer(arena));
      }
      lua.lua_settop(luaState, -2);
    });
  } finally {
    calloc.free(reg);
  }
}

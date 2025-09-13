import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:logging/logging.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/utility/luastrings.dart';
import 'package:ffi/ffi.dart';

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

import 'dart:ffi';

import 'package:dart_luajit_ffi/generated_bindings.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luastring.dart';

int luaError(Pointer<lua_State> luaState, String error) {
  var luaerr = error.toLuaString();
  lua.lua_pushstring(luaState, luaerr.ptr);

  return lua.lua_error(luaState);
}

int dartErrorToLua(
  Pointer<lua_State> luaState,
  Object error,
  StackTrace stackTrace,
) {
  /*  if (!dontLog)
    Logger.root.log(
      Level.WARNING,
      "Error forwarded to lua: $error",
      stackTrace,
    );*/
  return luaError(luaState, "Dart Error: $error\n$stackTrace");
}

int indexError(Pointer<lua_State> luaState, String index) =>
    luaError(luaState, "Attempt to index invalid key: $index");

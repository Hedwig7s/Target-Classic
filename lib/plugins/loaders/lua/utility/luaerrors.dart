import 'dart:ffi';

import 'package:dart_lua_ffi/macros.dart';
import 'package:ffi/ffi.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luastring.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/types.dart';

int luaError(LuaStateP luaState, String error) {
  var luaerr = error.toLuaString();
  lua.lua_pushstring(luaState, luaerr.ptr);

  return lua.lua_error(luaState);
}

int dartErrorToLua(LuaStateP luaState, Object error, StackTrace stackTrace) {
  /*  if (!dontLog)
    Logger.root.log(
      Level.WARNING,
      "Error forwarded to lua: $error",
      stackTrace,
    );*/
  lua.luaL_traceback(luaState, luaState, nullptr, 1);
  return luaError(
    luaState,
    "Dart Error: $error\n${stackTrace}Lua Stacktrace: ${lua.lua_tostring(luaState, -1).cast<Utf8>().toDartString()}",
  );
}

int indexError(LuaStateP luaState, String index) =>
    luaError(luaState, "Attempt to index invalid key: $index");

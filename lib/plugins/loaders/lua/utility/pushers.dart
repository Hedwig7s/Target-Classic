import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luastring.dart';

bool canPush(dynamic value) {
  bool can =
      value is String || value is int || value is double || value == null;
  return can;
}

void pushLiteralList(Pointer<lua_State> luaState, List list) {
  lua.lua_createtable(luaState, list.length, 0);
  for (int i = 0; i < list.length; i++) {
    if (!pushLiteral(luaState, list[i])) {
      throw Exception(
        "Couldn't push value ${list[i]} of type ${list[i].runtimeType}",
      );
    }
    lua.lua_rawseti(luaState, -2, i + 1);
  }
}

bool pushLiteral(Pointer<lua_State> luaState, dynamic value) {
  if (!canPush(value)) return false;
  if (value is String) {
    lua.lua_pushlstring(luaState, value.toLuaString().ptr, value.length);
    return true;
  } else if (value is int) {
    lua.lua_pushinteger(luaState, value);
    return true;
  } else if (value is double) {
    lua.lua_pushnumber(luaState, value);
    return true;
  } else if (value == null) {
    lua.lua_pushnil(luaState);
    return true;
  }
  return false;
}

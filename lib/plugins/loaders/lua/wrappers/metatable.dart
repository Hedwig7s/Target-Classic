import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:dart_lua_ffi/macros.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luareg.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luastring.dart';

void createMetatable(
  Pointer<lua_State> luaState,
  String name,
  List<RegFunction> functions, [
  bool setIndexToSelf = false,
]) {
  var reg = LuaReg.fromFunctions(functions);
  var metaname = name.toLuaString();
  lua.luaL_newmetatable(luaState, metaname.ptr);

  lua.luaL_setfuncs(luaState, reg.ptr, 0);
  if (setIndexToSelf) {
    lua.lua_pushvalue(luaState, -1); // copy metatable
    lua.lua_setfield(luaState, -2, "__index".toLuaString().ptr);
  }
  lua.lua_pop(luaState, 1);
}

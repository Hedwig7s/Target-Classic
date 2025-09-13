import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:dart_lua_ffi/macros.dart';
import 'package:ffi/ffi.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/utility/luastrings.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luareg.dart';

void createMetatable(
  Pointer<lua_State> luaState,
  String name,
  List<RegFunction> functions, [
  bool setIndexToSelf = false,
]) {
  using((arena) {
    var reg = LuaReg.createFromFunctions(functions);
    var metaname = name.toLuaPointer(arena);
    lua.luaL_newmetatable(luaState, metaname);

    lua.luaL_setfuncs(luaState, reg.ptr, 0);
    if (setIndexToSelf) {
      lua.lua_pushvalue(luaState, -1); // copy metatable
      lua.lua_setfield(luaState, -2, "__index".toLuaPointer(arena));
    }
    lua.lua_pop(luaState, 1);
  });
}

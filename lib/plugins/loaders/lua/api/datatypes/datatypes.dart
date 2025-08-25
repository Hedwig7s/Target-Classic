import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:target_classic/plugins/loaders/lua/api/datatypes/vector3.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/utility.dart';
import 'package:ffi/ffi.dart';

void registerDataTypes(Pointer<lua_State> luaState) {
  using((arena) {
    lua.lua_createtable(luaState, 0, 0);
    addVector3(luaState);
    lua.lua_setglobal(luaState, "DataTypes".toLuaPointer(arena));
  });
}

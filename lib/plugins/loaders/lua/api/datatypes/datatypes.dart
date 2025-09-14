import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:target_classic/plugins/loaders/lua/api/datatypes/vector3.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luastring.dart';

void registerDataTypes(Pointer<lua_State> luaState) {
  lua.lua_createtable(luaState, 0, 0);
  addVector3(luaState);
  lua.lua_setglobal(luaState, "DataTypes".toLuaString().ptr);
}

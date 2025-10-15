import 'package:target_classic/plugins/loaders/lua/api/datatypes/entityposition.dart';
import 'package:target_classic/plugins/loaders/lua/api/datatypes/vector3.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luastring.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/types.dart';

void registerDataTypes(LuaStateP luaState) {
  lua.lua_createtable(luaState, 0, 0);
  addVector3(luaState);
  addEntityPosition(luaState);
  lua.lua_setfield(luaState, -2, "DataTypes".toLuaString().ptr);
}

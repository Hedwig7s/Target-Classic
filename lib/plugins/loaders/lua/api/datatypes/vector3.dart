import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:target_classic/datatypes.dart';
import 'package:target_classic/plugins/loaders/lua/api/metatables.dart';
import 'package:target_classic/plugins/loaders/lua/utility/handles.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/utility/index.dart';
import 'package:target_classic/plugins/loaders/lua/utility/luaerrors.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luareg.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luastring.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/metatable.dart';
import 'package:ffi/ffi.dart';

int IVector3Index(Pointer<lua_State> luaState) {
  return using((arena) {
    try {
      var metaname = Metatables.Vector3.name.toLuaString();
      final userdata =
          lua.luaL_checkudata(luaState, 1, metaname.ptr).cast<Int64>();
      final vector3 = getObjectFromUserData<Vector3>(userdata);
      final sizeT = arena<Size>();
      final indexRaw = lua.luaL_checklstring(luaState, 2, sizeT);
      final int size = sizeT.value;
      final String index = LuaString.fromPointer(indexRaw, size).string;
      final map = vector3.toMap();
      if (!checkIndex(luaState, map.keys, index)) return -1;
      final num value = map[index]!;

      if (vector3 is Vector3I) {
        lua.lua_pushinteger(luaState, value.toInt());
      } else {
        lua.lua_pushnumber(luaState, value.toDouble());
      }
      return 1;
    } catch (e, s) {
      return dartErrorToLua(luaState, e, s);
    }
  });
}

void createIVector3Meta(Pointer<lua_State> luaState) => createMetatable(
  luaState,
  Metatables.Vector3.name,
  [GC_METAMETHOD, ("__index", IVector3Index)],
);


int createIVector3(Pointer<lua_State> luaState, bool isFloat) {
  try {
    late final Vector3 vector3;
    if (isFloat) {
      List<double> coords = [];
      for (int i = 1; i <= 3; i++) {
        coords.add(lua.luaL_checknumber(luaState, i));
      }
      vector3 = Vector3F(coords[0], coords[1], coords[2]);
    } else {
      List<int> coords = [];
      for (int i = 1; i <= 3; i++) {
        coords.add(lua.luaL_checkinteger(luaState, i));
      }
      vector3 = Vector3I(coords[0], coords[1], coords[2]);
    }
    createUserData(luaState, vector3, metatable: Metatables.Vector3.name);
    return 1;
  } catch (e, s) {
    return dartErrorToLua(luaState, e, s);
  }
}

int createIVector3I(Pointer<lua_State> luaState) =>
    createIVector3(luaState, false);

int createIVector3F(Pointer<lua_State> luaState) =>
    createIVector3(luaState, true);

void addVector3(Pointer<lua_State> luaState) {
  final reg = LuaReg.fromFunctions([
    ("newInt", createIVector3I),
    ("newFloat", createIVector3F),
  ]);
  createIVector3Meta(luaState);
  lua.lua_createtable(luaState, 0, 0);
  lua.luaL_setfuncs(luaState, reg.ptr, 0);
  var fieldName = "Vector3".toLuaString();
  lua.lua_setfield(luaState, -2, fieldName.ptr);
}

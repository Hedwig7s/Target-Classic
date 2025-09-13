import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:target_classic/datatypes.dart';
import 'package:target_classic/plugins/loaders/lua/utility/handles.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/utility/luaerrors.dart';
import 'package:target_classic/plugins/loaders/lua/utility/luastrings.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luareg.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/metatable.dart';
import 'package:ffi/ffi.dart';

int IVector3Index(Pointer<lua_State> luaState) {
  return using((arena) {
    try {
      var metaname = "datatypes.vector3".toLuaPointer(arena);
      final userdata = lua.luaL_checkudata(luaState, 1, metaname).cast<Int64>();
      final vector3 = getObjectFromUserData<Vector3>(userdata);
      final sizeT = arena<Size>();
      final indexPtr = lua.luaL_checklstring(luaState, 2, sizeT);
      final int size = sizeT.value;
      final String index = luaStringFromPointer(indexPtr, size);
      final num? value = vector3.toMap()[index];
      if (value == null)
        return luaError(
          luaState,
          "Attempt to index invalid key: ${index}",
        ); // TODO: Potentially make invalid index handling its own function
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
  "datatypes.vector3",
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
    createUserData(luaState, vector3, metatable: "datatypes.vector3");
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
  final reg = LuaReg.createFromFunctions([
    ("newInt", createIVector3I),
    ("newFloat", createIVector3F),
  ]);
  createIVector3Meta(luaState);
  lua.lua_createtable(luaState, 0, 0);
  lua.luaL_setfuncs(luaState, reg.ptr, 0);
  var fieldName = "Vector3".toLuaPointer();
  try {
    lua.lua_setfield(luaState, -2, fieldName);
  } finally {
    malloc.free(fieldName);
  }
}

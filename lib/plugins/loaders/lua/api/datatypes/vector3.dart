import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:target_classic/datatypes.dart';
import 'package:target_classic/plugins/loaders/lua/handles.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/utility.dart';
import 'package:ffi/ffi.dart';

int IVector3Index(Pointer<lua_State> luaState) {
  var metaname = "datatypes.vector3".toLuaPointer();
  try {
    final userdata = lua.luaL_checkudata(luaState, 1, metaname).cast<Int64>();
    final vector3 = getObjectFromUserData<Vector3>(userdata);
    final sizeT = calloc<Size>();
    final indexPtr = lua.luaL_checklstring(luaState, 2, sizeT);
    final int size = sizeT.value;
    calloc.free(sizeT);
    final String index = luaStringFromPointer(indexPtr, size);
    final num value;
    switch (index) {
      case "x":
        {
          value = vector3.x;
          break;
        }
      case "y":
        {
          value = vector3.y;
          break;
        }
      case "z":
        {
          value = vector3.z;
          break;
        }
      default:
        {
          return luaError(luaState, "Invalid index $index into Vector3");
        }
    }
    if (vector3 is Vector3I) {
      lua.lua_pushinteger(luaState, value.toInt());
    } else {
      lua.lua_pushnumber(luaState, value.toDouble());
    }
    return 1;
  } catch (e, s) {
    return dartErrorToLua(luaState, e, s);
  } finally {
    malloc.free(metaname);
  }
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
  using((arena) {
    final reg = calloc<luaL_Reg>(3);
    try {
      createIVector3Meta(luaState);
      lua.lua_createtable(luaState, 0, 0);
      reg[0].name = "newInt".toLuaPointer(
        arena,
      ); //TODO: Make a function for this
      reg[0].func = Pointer.fromFunction(createIVector3I, 1);
      reg[1].name = "newFloat".toLuaPointer(arena);
      reg[1].func = Pointer.fromFunction(createIVector3F, 1);
      lua.luaL_setfuncs(luaState, reg, 0);
      lua.lua_setfield(luaState, -2, "Vector3".toLuaPointer(arena));
    } finally {
      calloc.free(reg);
    }
  });
}

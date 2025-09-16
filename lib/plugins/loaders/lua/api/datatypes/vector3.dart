import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:dart_lua_ffi/macros.dart';
import 'package:target_classic/datatypes.dart';
import 'package:target_classic/plugins/loaders/lua/api/metatables.dart';
import 'package:target_classic/plugins/loaders/lua/utility/handles.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/utility/luaerrors.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luareg.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luastring.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/metatable.dart';
import 'package:ffi/ffi.dart';

int IVector3Index(Pointer<lua_State> luaState) {
  return using((arena) {
    try {
      final userdata = getHandleUserdata(luaState, Metatables.Vector3.name);
      final vector3 = getObjectFromUserData<Vector3>(userdata);
      final sizeT = arena<Size>();
      final indexRaw = lua.luaLD_checklstring(luaState, 2, sizeT);
      final int size = sizeT.value;
      final String index = LuaString.fromPointer(indexRaw, size).string;

      final map = vector3.toMap();
      final num? value = map[index];

      if (value != null) {
        if (vector3 is Vector3I) {
          lua.lua_pushinteger(luaState, value.toInt());
        } else {
          lua.lua_pushnumber(luaState, value.toDouble());
        }
        return 1;
      }
      lua.lua_getmetatable(luaState, 1);
      lua.lua_pushvalue(luaState, 2);
      lua.lua_gettable(luaState, -2);
      if (lua.luaD_isnil(luaState, -1)) indexError(luaState, index);
      return 1;
    } catch (e, s) {
      return dartErrorToLua(luaState, e, s);
    }
  });
}

int IVector3ToInt(Pointer<lua_State> luaState) {
  try {
    final userdata = getHandleUserdata(luaState, Metatables.Vector3.name);
    final vector3 = getObjectFromUserData<Vector3>(userdata);
    createIVector3(luaState, vector3: vector3.toInt());
    return 1;
  } catch (e, s) {
    return dartErrorToLua(luaState, e, s);
  }
}

int IVector3ToDouble(Pointer<lua_State> luaState) {
  try {
    final userdata = getHandleUserdata(luaState, Metatables.Vector3.name);
    final vector3 = getObjectFromUserData<Vector3>(userdata);
    createIVector3(luaState, vector3: vector3.toDouble());
    return 1;
  } catch (e, s) {
    return dartErrorToLua(luaState, e, s);
  }
}

void createIVector3Meta(Pointer<lua_State> luaState) =>
    createMetatable(luaState, Metatables.Vector3.name, [
      GC_METAMETHOD,
      ("__index", IVector3Index),
      ("__tostring", getToStringMetamethod(Metatables.Vector3)),
      ("toInt", IVector3ToInt),
      ("toDouble", IVector3ToDouble),
    ]);

int createIVector3(
  Pointer<lua_State> luaState, {
  bool? isFloat,
  Vector3? vector3,
}) {
  try {
    if (vector3 != null && isFloat != null)
      throw Exception("Vector3 can't be provided with an isFloat value");
    if (vector3 == null && isFloat == null)
      throw Exception("Either isFloat or Vector3 must be provided");

    if (isFloat == true) {
      List<double> coords = [];
      for (int i = 1; i <= 3; i++) {
        coords.add(lua.luaLD_checknumber(luaState, i));
      }
      vector3 = Vector3F(coords[0], coords[1], coords[2]);
    } else if (vector3 == null) {
      List<int> coords = [];
      for (int i = 1; i <= 3; i++) {
        coords.add(lua.luaLD_checkinteger(luaState, i));
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
    createIVector3(luaState, isFloat: false);

int createIVector3F(Pointer<lua_State> luaState) =>
    createIVector3(luaState, isFloat: true);

void addVector3(Pointer<lua_State> luaState) {
  final reg = LuaReg.fromFunctions([
    ("newInt", createIVector3I),
    ("newDouble", createIVector3F),
  ]);
  createIVector3Meta(luaState);
  lua.lua_createtable(luaState, 0, 0);
  lua.luaLD_setfuncs(luaState, reg.ptr, 0);
  var fieldName = "Vector3".toLuaString();
  lua.lua_setfield(luaState, -2, fieldName.ptr);
}


import 'package:dart_lua_ffi/macros.dart';
import 'package:target_classic/datatypes.dart';
import 'package:target_classic/plugins/loaders/lua/utility/functions.dart';
import 'package:target_classic/plugins/loaders/lua/utility/luaobjects.dart';
import 'package:target_classic/plugins/loaders/lua/utility/metatables.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/types.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/userdata.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/utility/luaerrors.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luareg.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luastring.dart';
import 'package:ffi/ffi.dart';

int Vector3Index(LuaStateP luaState) {
  return using((arena) {
    try {
      final (vector3, index) = getIndexData<Vector3>(
        luaState,
        Metatables.Vector3,
      );

      final map = vector3.toMap();
      final num? value = map[index];

      if (value != null) {
        if (vector3 is Vector3I) {
          lua.lua_pushinteger(luaState, value.toInt());
        } else {
          lua.lua_pushnumber(luaState, value.toDouble());
        }
        return 1;
      } else if (index == "_type") {
        lua.lua_pushstring(
          luaState,
          vector3.runtimeType.toString().toLuaPointer(arena),
        );
        return 1;
      }
      getFromMetatable(luaState, index);
      if (lua.lua_isnil(luaState, -1)) return indexError(luaState, index);
      return 1;
    } catch (e, s) {
      return dartErrorToLua(luaState, e, s);
    }
  });
}

LuaCallback transformVector3<R>(
  R Function(Vector3 vector3) transformFunction,
) => transformObject<Vector3, R>(Metatables.Vector3, transformFunction);

LuaCallback calculateOnVector3<O, R>(
  R Function(Vector3 vector3, O other) calculateFunction,
) => calculateOnObject(Metatables.Vector3, calculateFunction);

void createVector3Meta(
  LuaStateP luaState,
) => createMetatable(luaState, Metatables.Vector3.name, [
  GC_METAMETHOD,
  ("__index", Vector3Index),
  ("__tostring", getToStringMetamethod(Metatables.Vector3)),
  ("__eq", getEqualityMetamethod(Metatables.Vector3)),
  (
    "__unm",
    transformVector3(
      (Vector3 vector3) => Vector3(-vector3.x, -vector3.y, -vector3.z),
    ),
  ),
  ("toInt", transformVector3((Vector3 vector3) => vector3.toInt())),
  ("toDouble", transformVector3((Vector3 vector3) => vector3.toDouble())),
  (
    "toClientCoordinates",
    transformVector3((Vector3 vector3) => vector3.toClientCoordinates()),
  ),
  (
    "__add",
    calculateOnVector3((Vector3 vector3, Vector3 other) => vector3 + other),
  ),
  (
    "__sub",
    calculateOnVector3((Vector3 vector3, Vector3 other) => vector3 - other),
  ),
  (
    "__mod",
    calculateOnVector3((Vector3 vector3, double scalar) => vector3 % scalar),
  ),
  (
    "__pow",
    calculateOnVector3((Vector3 vector3, double scalar) => vector3.pow(scalar)),
  ),
  (
    "__mul",
    wrapObjectFunction<Vector3>(Metatables.Vector3, (
      luaState,
      userdata,
      vector3,
    ) {
      double scalar = getValue<double>(luaState, 2).$1;
      int scalarInt = scalar.toInt();
      if (scalarInt == scalar) {
        pushValue(luaState, vector3 * scalarInt);
      } else {
        pushValue(luaState, vector3 * scalar);
      }
      return 1;
    }),
  ),

  (
    "__div",
    calculateOnVector3((Vector3 vector3, double other) => vector3 / other),
  ),
  (
    "__idiv",
    calculateOnVector3((Vector3 vector3, int other) => vector3 ~/ other),
  ),
  (
    "dot",
    calculateOnVector3((Vector3 vector3, Vector3 other) => vector3.dot(other)),
  ),
  (
    "__len",
    wrapObjectFunction<Vector3>(Metatables.Vector3, (
      luaState,
      userdata,
      vector3,
    ) {
      lua.lua_pushnumber(luaState, vector3.magnitude());
      return 1;
    }),
  ),
  (
    "magnitude",
    wrapObjectFunction<Vector3>(Metatables.Vector3, (
      luaState,
      userdata,
      vector3,
    ) {
      lua.lua_pushnumber(luaState, vector3.magnitude());
      return 1;
    }),
  ),
]);

int createVector3(LuaStateP luaState, {bool? isFloat, Vector3? vector3}) {
  try {
    if (vector3 != null && isFloat != null) {
      throw Exception("Vector3 can't be provided with an isFloat value");
    }
    if (vector3 == null && isFloat == null) {
      throw Exception("Either isFloat or Vector3 must be provided");
    }

    if (isFloat == true) {
      List<double> coords = [];
      for (int i = 1; i <= 3; i++) {
        coords.add(lua.luaL_checknumber(luaState, i));
      }
      vector3 = Vector3F(coords[0], coords[1], coords[2]);
    } else if (vector3 == null) {
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

int createVector3I(LuaStateP luaState) =>
    createVector3(luaState, isFloat: false);

int createVector3F(LuaStateP luaState) =>
    createVector3(luaState, isFloat: true);

void addVector3(LuaStateP luaState) {
  final reg = LuaReg.fromFunctions([
    ("newInt", createVector3I),
    ("newDouble", createVector3F),
  ]);
  createVector3Meta(luaState);
  lua.lua_createtable(luaState, 0, 0);
  lua.luaL_setfuncs(luaState, reg.ptr, 0);
  var fieldName = "Vector3".toLuaString();
  lua.lua_setfield(luaState, -2, fieldName.ptr);
}

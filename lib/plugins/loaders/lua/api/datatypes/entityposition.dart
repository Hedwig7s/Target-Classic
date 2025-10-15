import 'package:target_classic/datatypes.dart';
import 'package:target_classic/plugins/loaders/lua/api/datatypes/vector3.dart';
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

int EntityPositionIndex(LuaStateP luaState) {
  return using((arena) {
    try {
      final (entityPosition, index) = getIndexData<EntityPosition>(
        luaState,
        Metatables.EntityPosition,
      );
      final map = entityPosition.toMap();
      final dynamic value = map[index];
      if (map.containsKey(index)) {
        pushValue(luaState, value);
      } else if (index == "_type") {
        lua.lua_pushstring(
          luaState,
          entityPosition.runtimeType.toString().toLuaPointer(arena),
        );
        return 1;
      }
      return 1;
    } catch (e, s) {
      return dartErrorToLua(luaState, e, s);
    }
  });
}

LuaCallback calculateOnEntityPosition<R, O>(
  R Function(EntityPosition position, O other) calculateFunction,
) => calculateOnObject<EntityPosition, O, R>(
  Metatables.EntityPosition,
  calculateFunction,
);

void createEntityPositionMeta(
  LuaStateP luaState,
) => createMetatable(luaState, Metatables.EntityPosition.name, [
  GC_METAMETHOD,
  ("__index", EntityPositionIndex),
  ("__tostring", getToStringMetamethod(Metatables.EntityPosition)),
  ("__eq", getEqualityMetamethod(Metatables.EntityPosition)),
  (
    "toClientCoordinates",
    transformObject(
      Metatables.EntityPosition,
      (EntityPosition entityPosition) => entityPosition.toClientCoordinates(),
    ),
  ),
  (
    "__add",
    calculateOnEntityPosition(
      (position, EntityPosition other) => position + other,
    ),
  ),
  (
    "__sub",
    calculateOnEntityPosition(
      (position, EntityPosition other) => position - other,
    ),
  ),
  (
    "__mul",
    calculateOnEntityPosition((position, double scalar) => position * scalar),
  ),
  (
    "__div",
    calculateOnEntityPosition((position, double scalar) => position / scalar),
  ),
  (
    "__idiv",
    calculateOnEntityPosition((position, int scalar) => position ~/ scalar),
  ),
]);

int createEntityPosition(LuaStateP luaState, [EntityPosition? entityPosition]) {
  try {
    if (entityPosition == null) {
      List<double> coords = [];
      for (int i = 1; i <= 3; i++) {
        coords.add(lua.luaL_checknumber(luaState, i));
      }
      List<int> rotation = [];
      for (int i = 4; i <= 5; i++) {
        rotation.add(lua.luaL_checkinteger(luaState, i));
      }
      entityPosition = EntityPosition(
        coords[0],
        coords[1],
        coords[2],
        rotation[0],
        rotation[1],
      );
    }
    createUserData(
      luaState,
      entityPosition,
      metatable: Metatables.EntityPosition.name,
      nuvalue: 1,
    );
    createVector3(luaState, vector3: entityPosition.vector);
    setUserValueOnStack(luaState, -2, 1);
    return 1;
  } catch (e, s) {
    return dartErrorToLua(luaState, e, s);
  }
}

int createEntityPositionFromVector3(LuaStateP luaState) {
  try {
    Vector3F vector3 =
        getObjectFromStack(luaState, Metatables.Vector3.name, 1).$2;
    int yaw = lua.luaL_checkinteger(luaState, 2);
    int pitch = lua.luaL_checkinteger(luaState, 3);
    return createEntityPosition(
      luaState,
      EntityPosition.fromVector3(vector: vector3, yaw: yaw, pitch: pitch),
    );
  } catch (e, s) {
    return dartErrorToLua(luaState, e, s);
  }
}

void addEntityPosition(LuaStateP luaState) {
  final reg = LuaReg.fromFunctions([
    ("new", createEntityPosition),
    ("fromVector3", createEntityPositionFromVector3),
  ]);
  createEntityPositionMeta(luaState);
  lua.lua_createtable(luaState, 0, 0);
  lua.luaL_setfuncs(luaState, reg.ptr, 0);
  var fieldName = "EntityPosition".toLuaString();
  lua.lua_setfield(luaState, -2, fieldName.ptr);
}

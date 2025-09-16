import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:dart_lua_ffi/macros.dart';
import 'package:target_classic/datatypes.dart';
import 'package:target_classic/plugins/loaders/lua/api/datatypes/vector3.dart';
import 'package:target_classic/plugins/loaders/lua/api/metatables.dart';
import 'package:target_classic/plugins/loaders/lua/utility/handles.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/utility/luaerrors.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luareg.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luastring.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/metatable.dart';
import 'package:ffi/ffi.dart';

int EntityPositionIndex(Pointer<lua_State> luaState) {
  return using((arena) {
    try {
      final userdata =
          lua
              .luaLD_checkudata(luaState, 1, Metatables.EntityPosition.name)
              .cast<Int64>();
      final entityPosition = getObjectFromUserData<EntityPosition>(userdata);
      final sizeT = arena<Size>();
      final indexRaw = lua.luaLD_checklstring(luaState, 2, sizeT);
      final int size = sizeT.value;
      final String index = LuaString.fromPointer(indexRaw, size).string;
      final map = entityPosition.toMap();
      if (!map.keys.contains(index)) return indexError(luaState, index);
      final dynamic value = map[index]!;
      if (["x", "y", "z"].contains(index)) {
        lua.lua_pushnumber(luaState, value as double);
      } else if (["yaw", "pitch"].contains(index)) {
        lua.lua_pushinteger(luaState, value as int);
      } else if (index == "vector") {
        lua.lua_getiuservalue(luaState, 1, 1);
      }
      return 1;
    } catch (e, s) {
      return dartErrorToLua(luaState, e, s);
    }
  });
}

void createEntityPositionMeta(Pointer<lua_State> luaState) =>
    createMetatable(luaState, Metatables.EntityPosition.name, [
      GC_METAMETHOD,
      ("__index", EntityPositionIndex),
      ("__tostring", getToStringMetamethod(Metatables.EntityPosition)),
    ]);

int createEntityPosition(Pointer<lua_State> luaState) {
  try {
    late final EntityPosition entityPosition;
    List<double> coords = [];
    for (int i = 1; i <= 3; i++) {
      coords.add(lua.luaLD_checknumber(luaState, i));
    }
    List<int> rotation = [];
    for (int i = 4; i <= 5; i++) {
      rotation.add(lua.luaLD_checkinteger(luaState, i));
    }
    entityPosition = EntityPosition(
      coords[0],
      coords[1],
      coords[2],
      rotation[0],
      rotation[1],
    );
    createUserData(
      luaState,
      entityPosition,
      metatable: Metatables.EntityPosition.name,
      nuvalue: 1,
    );
    createIVector3(luaState, vector3: entityPosition.vector);
    lua.lua_setiuservalue(luaState, -2, 1);
    return 1;
  } catch (e, s) {
    return dartErrorToLua(luaState, e, s);
  }
}

void addEntityPosition(Pointer<lua_State> luaState) {
  final reg = LuaReg.fromFunctions([("new", createEntityPosition)]);
  createEntityPositionMeta(luaState);
  lua.lua_createtable(luaState, 0, 0);
  lua.luaLD_setfuncs(luaState, reg.ptr, 0);
  var fieldName = "EntityPosition".toLuaString();
  lua.lua_setfield(luaState, -2, fieldName.ptr);
}

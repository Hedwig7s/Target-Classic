import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:dart_lua_ffi/macros.dart';
import 'package:ffi/ffi.dart';
import 'package:target_classic/datatypes.dart';
import 'package:target_classic/plugins/loaders/lua/api/datatypes/entityposition.dart';
import 'package:target_classic/plugins/loaders/lua/api/datatypes/vector3.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luastring.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/types.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/userdata.dart';

final _pushers = <Type, void Function(LuaStateP, dynamic)>{
  String:
      (luaState, value) => lua.lua_pushlstring(
        luaState,
        (value as String).toLuaString().ptr,
        value.length,
      ),
  int: (luaState, value) => lua.lua_pushinteger(luaState, value as int),
  double: (luaState, value) => lua.lua_pushnumber(luaState, value as double),
  Vector3:
      (luaState, value) => createVector3(luaState, vector3: value as Vector3),
  EntityPosition:
      (luaState, value) =>
          createEntityPosition(luaState, value as EntityPosition),
};

bool canPush(dynamic value) => _pushers.containsKey(value.runtimeType);

void pushList(LuaStateP luaState, List list) {
  lua.lua_createtable(luaState, list.length, 0);
  for (int i = 0; i < list.length; i++) {
    if (!pushValue(luaState, list[i])) {
      throw Exception(
        "Couldn't push value ${list[i]} of type ${list[i].runtimeType}",
      );
    }
    lua.lua_rawseti(luaState, -2, i + 1);
  }
}

bool pushValue(LuaStateP luaState, dynamic value) {
  if (value == null) {
    lua.lua_pushnil(luaState);
    return true;
  }
  final pusher = _pushers[value.runtimeType];
  if (pusher == null) return false;
  pusher(luaState, value);
  return true;
}

(dynamic value, int type) getValue<ExpectedType>(
  LuaStateP luaState,
  int stackIndex, [
  String? metatable,
]) {
  final type = lua.lua_type(luaState, stackIndex);
  dynamic ret;
  switch (type) {
    case (LUA_TNIL):
      {
        ret = null;
        break;
      }
    case (LUA_TNUMBER):
      {
        ret = lua.lua_tonumber(luaState, stackIndex);
        break;
      }
    case (LUA_TBOOLEAN):
      {
        ret = lua.lua_toboolean(luaState, stackIndex) == 1;
        break;
      }
    case (LUA_TSTRING):
      {
        ret =
            lua.lua_tostring(luaState, stackIndex).cast<Utf8>().toDartString();
        break;
      }
    case (LUA_TUSERDATA):
      {
        ret = getObjectFromStack(luaState, metatable, stackIndex).$2;
        break;
      }
    case (LUA_TLIGHTUSERDATA):
      {
        ret = lua.lua_topointer(luaState, stackIndex);
        break;
      }
    // TODO
    case (LUA_TTABLE):
      {
        throw UnimplementedError();
      }
    case (LUA_TFUNCTION):
      {
        throw UnimplementedError();
      }
    case (LUA_TTHREAD):
      {
        throw UnimplementedError();
      }
    default:
      {
        throw ArgumentError(
          "Unknown lua type ${lua.lua_typename(luaState, type).cast<Utf8>.toString()}",
        );
      }
  }
  if (ExpectedType == int && ret is double) {
    int val = ret.toInt();
    if (val != ret) {
      throw Exception(
        "Expected type $ExpectedType, got double which could not be converted to int. $val, $ret",
      );
    }
    ret = val;
  }
  if (ret is! ExpectedType) {
    throw Exception(
      "Expected type $ExpectedType, got ${ret.runtimeType} of type ${lua.lua_typename(luaState, type).cast<Utf8>().toDartString()}",
    );
  }
  return (ret, type);
}

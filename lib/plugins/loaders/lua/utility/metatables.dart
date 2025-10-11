// ignore_for_file: constant_identifier_names

import 'dart:ffi';

import 'package:dart_luajit_ffi/generated_bindings.dart';
import 'package:dart_luajit_ffi/macros.dart';
import 'package:ffi/ffi.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/utility/luaerrors.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/userdata.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luareg.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luastring.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/types.dart';

enum Metatables {
  Vector3("vector3"),
  EntityPosition("entityposition"),
  Command("command"),
  ParameterParser("parameterparser");

  final String name;
  const Metatables(String name) : name = "mcclassic.$name";
}

void createMetatable(
  Pointer<lua_State> luaState,
  String name,
  List<RegFunction> functions, [
  bool setIndexToSelf = false,
]) {
  var reg = LuaReg.fromFunctions(functions);
  var metaname = name.toLuaString();
  lua.luaL_newmetatable(luaState, metaname.ptr);

  lua.luaL_setfuncs(luaState, reg.ptr, 0);
  if (setIndexToSelf) {
    lua.lua_pushvalue(luaState, -1); // copy metatable
    lua.lua_setfield(luaState, -2, "__index".toLuaString().ptr);
  }
  lua.lua_pop(luaState, 1);
}

LuaCallback getToStringMetamethod(Metatables metatable) {
  return (Pointer<lua_State> luaState) {
    try {
      var object = getObjectFromStack(luaState, metatable.name, 1);
      final string = object.$2.toString().toLuaString();
      lua.lua_pushlstring(luaState, string.ptr, string.string.length);
      return 1;
    } catch (e, s) {
      return dartErrorToLua(luaState, e, s);
    }
  };
}

LuaCallback getEqualityMetamethod(Metatables metatable) {
  return (Pointer<lua_State> luaState) {
    try {
      var object = getObjectFromStack(luaState, metatable.name, 1).$2;
      var other = getObjectFromStack(luaState, null, 2).$2;

      lua.lua_pushboolean(luaState, object == other ? 1 : 0);
      return 1;
    } catch (e, s) {
      return dartErrorToLua(luaState, e, s);
    }
  };
}

void getFromMetatable(Pointer<lua_State> luaState, String index) {
  lua.lua_getmetatable(luaState, 1);
  lua.lua_pushstring(luaState, index.toLuaString().ptr);
  lua.lua_gettable(luaState, -2);
}

(T instance, String index) getIndexData<T>(
  Pointer<lua_State> luaState,
  Metatables metatable,
) {
  return using((arena) {
    final instance = getObjectFromStack<T>(luaState, metatable.name, 1).$2;
    final sizeT = arena<Size>();
    final indexRaw = lua.luaL_checklstring(luaState, 2, sizeT);
    final int size = sizeT.value;
    final String index = LuaString.fromPointer(indexRaw, size).string;
    return (instance, index);
  });
}

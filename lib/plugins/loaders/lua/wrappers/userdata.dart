import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/utility/luaerrors.dart';
import 'package:target_classic/plugins/loaders/lua/utility/metatables.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luareg.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luastring.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/types.dart';

class IncorrectTypeError implements Exception {
  String message;
  IncorrectTypeError(this.message);
}

final Map<int, Object> _handles = {};
int _nextHandle = 1;

int storeObject(Object obj) {
  final handle = _nextHandle++;
  _handles[handle] = obj;
  return handle;
}

T retrieveObject<T>(int handle) {
  Object object = _handles[handle]!;
  if (object is! T) {
    throw IncorrectTypeError(
      "Attempted to retrieve object of type $T. Got ${object.runtimeType}",
    );
  }
  return object as T;
}

void removeObject(int handle) {
  _handles.remove(handle);
}

int handleGCCallback(LuaStateP L) {
  try {
    Pointer<DartDataStruct> ptr =
        lua
            .luaL_checkudata(L, 1, "handlecleanup".toLuaString().ptr)
            .cast<DartDataStruct>();
    removeObject(ptr.ref.handle);
    for (int i = 0; i < ptr.ref.nuvalues; i++) {
      lua.luaL_unref(L, LUA_REGISTRYINDEX, ptr.ref.uservalues[i]);
    }
    return 0;
  } catch (e, s) {
    return dartErrorToLua(L, e, s);
  }
}

final RegFunction GC_METAMETHOD = ("__gc", handleGCCallback);

final class DartDataStruct extends Struct {
  @Size()
  external int nuvalues;
  @Uint64()
  external int handle;
  @Array.variable()
  external Array<Int> uservalues; // Meant for luaL_ref values

  static int getSize(int nuvalues) =>
      sizeOf<DartDataStruct>() + sizeOf<Uint64>() * nuvalues;
  static Pointer<DartDataStruct> allocate(Allocator allocator, int nuvalues) {
    final lengthInBytes = getSize(nuvalues);
    final result = allocator.allocate<DartDataStruct>(lengthInBytes);
    result.ref.nuvalues = nuvalues;
    for (int i = 0; i < nuvalues; i++) {
      result.ref.uservalues[i] = LUA_NOREF;
    }
    return result;
  }
}

void createHandleGCMetatable(LuaStateP luaState) =>
    createMetatable(luaState, "handlecleanup", [GC_METAMETHOD]);

(Pointer<DartDataStruct> userdata, int handle) createUserData(
  LuaStateP luaState,
  Object object, {
  int nuvalue = 0,
  String metatable = "handlecleanup",
}) {
  var userdata =
      lua
          .lua_newuserdatauv(luaState, DartDataStruct.getSize(nuvalue), 0)
          .cast<DartDataStruct>();
  int handle = storeObject(object);
  userdata.ref.nuvalues = nuvalue;
  userdata.ref.handle = handle;
  lua.luaL_setmetatable(luaState, metatable.toLuaString().ptr);
  return (userdata, handle);
}

T getObjectFromUserData<T>(Pointer<DartDataStruct> userdata) =>
    retrieveObject<T>(userdata.ref.handle);

void checkUserValueBounds(Pointer<DartDataStruct> userdata, int uservalue) {
  if (uservalue < 1 || uservalue > userdata.ref.nuvalues) {
    throw ArgumentError.value(
      uservalue,
      "uservalue",
      "Uservalue $uservalue outside range 1-${userdata.ref.nuvalues}",
    );
  }
}

void getUserValue(
  LuaStateP luaState,
  Pointer<DartDataStruct> userdata,
  int uservalue,
) {
  checkUserValueBounds(userdata, uservalue);
  int ref = userdata.ref.uservalues[uservalue - 1];
  if (ref != LUA_NOREF && ref != LUA_REFNIL) {
    lua.lua_rawgeti(luaState, LUA_REGISTRYINDEX, ref);
  } else {
    lua.lua_pushnil(luaState);
  }
}

void getUserValueFromStack(
  LuaStateP luaState,
  int userdataIndex,
  int uservalue,
) {
  var userdata = getHandleUserdataUnchecked(luaState, userdataIndex);
  return getUserValue(luaState, userdata, uservalue);
}

void setUserValue(
  LuaStateP luaState,
  Pointer<DartDataStruct> userdata,
  int uservalue, [
  int valueIndex = -1,
]) {
  checkUserValueBounds(userdata, uservalue);
  int idx = uservalue - 1;
  if (!const [LUA_NOREF, LUA_REFNIL].contains(userdata.ref.uservalues[idx])) {
    lua.luaL_unref(luaState, LUA_REGISTRYINDEX, userdata.ref.uservalues[idx]);
    userdata.ref.uservalues[idx] = LUA_NOREF;
  }
  userdata.ref.uservalues[idx] = lua.luaL_ref(luaState, LUA_REGISTRYINDEX);
}

void setUserValueOnStack(
  LuaStateP luaState,
  int userdataIndex,
  int uservalue, [
  int valueIndex = -1,
]) {
  var userdata = getHandleUserdataUnchecked(luaState, userdataIndex);
  setUserValue(luaState, userdata, uservalue, valueIndex);
}

Pointer<DartDataStruct> getHandleUserdata(
  LuaStateP luaState,
  String metatable, [
  int valueIndex = 1,
]) {
  return lua
      .luaL_checkudata(luaState, valueIndex, metatable.toLuaString().ptr)
      .cast<DartDataStruct>();
}

Pointer<DartDataStruct> getHandleUserdataUnchecked(
  LuaStateP luaState,
  int valueIndex,
) {
  return lua.lua_touserdata(luaState, valueIndex).cast<DartDataStruct>();
}

(Pointer<DartDataStruct> userdata, T object) getObjectFromStack<T>(
  LuaStateP luaState,
  String? metatable,
  int valueIndex,
) {
  final userdata =
      metatable != null
          ? getHandleUserdata(luaState, metatable, valueIndex)
          : getHandleUserdataUnchecked(luaState, valueIndex);
  final object = getObjectFromUserData<T>(userdata);
  return (userdata, object);
}

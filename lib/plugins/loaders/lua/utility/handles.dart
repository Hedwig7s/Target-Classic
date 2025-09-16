import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:dart_lua_ffi/macros.dart';
import 'package:target_classic/plugins/loaders/lua/api/metatables.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/utility/luaerrors.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luareg.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luastring.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/metatable.dart';
import 'package:ffi/ffi.dart';

class IncorrectTypeError implements Exception {
  String message;
  IncorrectTypeError(this.message);
}

final HANDLE_SIZE = sizeOf<Int64>();

final Map<int, Object> _handles = {};
int _nextHandle = 1;

int storeObject(Object obj) {
  final handle = _nextHandle++;
  _handles[handle] = obj;
  return handle;
}

T retrieveObject<T>(int handle) {
  Object object = _handles[handle]!;
  if (object is! T)
    throw IncorrectTypeError(
      "Attempted to retrieve object of type $T. Got ${object.runtimeType}",
    );
  return object as T;
}

void removeObject(int handle) {
  _handles.remove(handle);
}

int handleGCCallback(Pointer<lua_State> L) {
  try {
    Pointer<Int64> ptr =
        lua.luaLD_checkudata(L, 1, "handlecleanup").cast<Int64>();
    removeObject(ptr.value);
    return 0;
  } catch (e, s) {
    return dartErrorToLua(L, e, s);
  }
}

final RegFunction GC_METAMETHOD = ("__gc", handleGCCallback);

void createHandleGCMetatable(Pointer<lua_State> luaState) =>
    createMetatable(luaState, "handlecleanup", [GC_METAMETHOD]);

(Pointer<Int64> userdata, int handle) createUserData(
  Pointer<lua_State> luaState,
  Object object, {
  int nuvalue = 0,
  String metatable = "handlecleanup",
}) {
  var userdata =
      lua.lua_newuserdatauv(luaState, HANDLE_SIZE, nuvalue).cast<Int64>();
  int handle = storeObject(object);
  userdata.value = handle;
  var metaname = metatable.toLuaPointer();
  try {
    lua.luaL_setmetatable(luaState, metaname);
  } finally {
    malloc.free(metaname);
  }

  return (userdata, handle);
}

T getObjectFromUserData<T>(Pointer<Int64> userdata) =>
    retrieveObject<T>(userdata.value);

Pointer<Int64> getHandleUserdata(
  Pointer<lua_State> luaState,
  String metatable,
) {
  return lua.luaLD_checkudata(luaState, 1, metatable).cast<Int64>();
}

import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:target_classic/plugins/loaders/lua/luaplugin.dart';
import 'package:target_classic/plugins/loaders/lua/utility/handles.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luastring.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/types.dart';

enum Metatables {
  Vector3("vector3"),
  EntityPosition("entityposition");

  const Metatables(name) : this.name = "mcclassic." + name;
  final String name;
}

LuaCallback getToStringMetamethod(Metatables metatable) {
  return (Pointer<lua_State> luaState) {
    var handle = getHandleUserdata(luaState, metatable.name);
    var object = getObjectFromUserData(handle);
    final string = object.toString().toLuaString();
    lua.lua_pushlstring(luaState, string.ptr, string.string.length);
    return 1;
  };
}

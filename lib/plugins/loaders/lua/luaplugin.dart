import 'dart:ffi';
import 'dart:io';

import 'package:dart_lua_ffi/dart_lua_ffi.dart';
import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:dart_lua_ffi/macros.dart';
import 'package:target_classic/plugins/loaders/lua/api/datatypes/datatypes.dart';
import 'package:target_classic/plugins/loaders/lua/utility/handles.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/luastring.dart';
import 'package:target_classic/plugins/loaders/pluginloader.dart';
import 'package:target_classic/plugins/plugin.dart';
import 'package:path/path.dart' as p;
import 'package:ffi/ffi.dart';

const luaLibraryNames = {
  "windows": "lua54.dll",
  "macos": "liblua5.4.dylib",
  "ios": "liblua5.4.dylib",
  "linux": "liblua5.4.so",
  "android": "liblua5.4.so",
  "fuschia": "liblua5.4.so",
};

LuaFFIBind makeLua() {
  LuaFFIBind luaFFI = createLua(
    "assets/" + luaLibraryNames[Platform.operatingSystem]!,
  );
  return luaFFI;
}

final lua = makeLua();

void setupLuaState(Pointer<lua_State> luaState) {
  //TODO: Sandboxing
  lua.luaL_openlibs(luaState);
  createHandleGCMetatable(luaState);
  lua.lua_createtable(luaState, 0, 0);
  registerDataTypes(luaState);
  lua.lua_setglobal(luaState, "Classic".toLuaString().ptr);
}

class LuaPluginLoader implements PluginLoader {
  final String filePath;
  Pointer<lua_State>? luaState;
  bool loaded = false;
  Plugin? plugin;
  LuaPluginLoader(this.filePath);
  load() {
    if (this.loaded)
      throw Exception(
        "Cannot load when already loaded. Please unload first or use reload",
      );
    this.loaded = true;
    luaState = lua.luaL_newstate();
    setupLuaState(luaState!);
    var luaPath = p.absolute(filePath).toLuaString();
    lua.luaL_loadfile(luaState!, luaPath.ptr); // TODO: Error handling
    bool errored = lua.lua_pcall(luaState!, 0, LUA_MULTRET, 0) != 0;
    if (errored) {
      final Pointer<Utf8> errorPointer =
          lua.lua_tostring(luaState!, -1).cast<Utf8>();

      final error = errorPointer.toDartString();
      throw Exception("Lua error: ${error}");
    }
  }
}

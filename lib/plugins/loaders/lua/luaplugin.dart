import 'dart:ffi';
import 'dart:io';

import 'package:dart_lua_ffi/dart_lua_ffi.dart';
import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:dart_lua_ffi/macros.dart';
import 'package:logging/logging.dart';
import 'package:target_classic/plugins/loaders/lua/api/datatypes/datatypes.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/userdata.dart';
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
    "assets/${luaLibraryNames[Platform.operatingSystem]!}",
  );
  return luaFFI;
}

LuaFFIBind? _lua;
bool failedLoad = false;

LuaFFIBind? tryMakeLua() {
  if (failedLoad && _lua != null) return _lua;
  try {
    _lua = makeLua();
  } catch (e) {
    Logger.root.warning("Failed to load lua library: $e");
    failedLoad = true;
  }
  return _lua;
}

LuaFFIBind? get luaOptional => _lua ?? tryMakeLua();

LuaFFIBind get lua => _lua!;
int atPanic(Pointer<lua_State> L) {
  final msg = lua.lua_tostring(L, -1).cast<Utf8>().toDartString();
  Logger.root.severe("Lua panic: $msg");
  return 0;
}

void setupLuaState(Pointer<lua_State> luaState) {
  //TODO: Sandboxing and isolatesliblua
  lua.luaL_openlibs(luaState);
  lua.lua_atpanic(
    luaState,
    Pointer.fromFunction<Int Function(Pointer<lua_State>)>(atPanic, 0),
  );
  createHandleGCMetatable(luaState);
  lua.lua_createtable(luaState, 0, 0);
  registerDataTypes(luaState);
  lua.lua_setglobal(luaState, "Classic".toLuaString().ptr);
}

class LuaPluginLoader implements PluginLoader {
  final String filePath;
  Pointer<lua_State>? luaState;
  @override
  bool loaded = false;
  @override
  Plugin? plugin;
  LuaPluginLoader(this.filePath);
  @override
  load() {
    tryMakeLua();
    if (luaOptional == null) {
      throw Exception(
        "Lua unavailable. Cannot load plugin ${p.basename(filePath)}.",
      );
    }
    if (loaded) {
      throw Exception(
        "Cannot load when already loaded. Please unload first or use reload",
      );
    }
    loaded = true;
    luaState = lua.luaL_newstate();
    setupLuaState(luaState!);
    var luaPath = p.absolute(filePath).toLuaString();
    lua.luaL_loadfile(luaState!, luaPath.ptr);

    bool errored = lua.lua_pcall(luaState!, 0, LUA_MULTRET, 0) != LUA_OK;
    if (errored) {
      final Pointer<Utf8> errorPointer =
          lua.lua_tostring(luaState!, -1).cast<Utf8>();

      final error = errorPointer.toDartString();
      throw Exception("Lua error: $error");
    }
  }
}

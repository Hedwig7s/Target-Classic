import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';

typedef LuaStateP = Pointer<lua_State>;
typedef LuaCallback = int Function(LuaStateP);
typedef LuaNativeCallback = Int Function(LuaStateP);

typedef LuaCallable = NativeCallable<LuaNativeCallback>;

import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';

typedef LuaCallback = int Function(Pointer<lua_State>);
typedef LuaNativeCallback = Int Function(Pointer<lua_State>);

typedef LuaCallable = NativeCallable<LuaNativeCallback>;
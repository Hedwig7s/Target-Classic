import 'dart:ffi';

import 'package:target_classic/plugins/loaders/lua/wrappers/types.dart';

final callables = <Function, LuaCallable>{};

LuaCallable getCallable(LuaCallback func) {
  if (callables.containsKey(func)) return callables[func]!;
  final callable = NativeCallable<LuaNativeCallback>.isolateLocal(
    func,
    exceptionalReturn: 1,
  );
  callables[func] = callable;
  return callable;
}

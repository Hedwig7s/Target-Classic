import 'dart:ffi';

import 'package:target_classic/plugins/loaders/lua/utility/luaerrors.dart';
import 'package:target_classic/plugins/loaders/lua/utility/luaobjects.dart';
import 'package:target_classic/plugins/loaders/lua/utility/metatables.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/types.dart';
import 'package:target_classic/plugins/loaders/lua/wrappers/userdata.dart';

LuaCallback wrapObjectFunction<T>(
  Metatables metatable,
  int Function(LuaStateP luaState, Pointer<DartDataStruct> userdata, T object)
  wrappedFunction,
) {
  return (LuaStateP luaState) {
    try {
      final (userdata, object) = getObjectFromStack<T>(
        luaState,
        metatable.name,
        1,
      );
      return wrappedFunction(luaState, userdata, object);
    } catch (e, s) {
      return dartErrorToLua(luaState, e, s);
    }
  };
}

LuaCallback transformObject<T, R>(
  Metatables metatable,
  R Function(T object) transformFunction,
) => wrapObjectFunction(metatable, (
  LuaStateP luaState,
  Pointer<DartDataStruct> userdata,
  T object,
) {
  pushValue(luaState, transformFunction);
  return 1;
});

LuaCallback calculateOnObject<T, O, R>(
  Metatables metatable,
  R Function(T object, O other) calculateFunction,
) => wrapObjectFunction(metatable, (
  LuaStateP luaState,
  Pointer<DartDataStruct> userdata,
  T object,
) {
  pushValue(
    luaState,
    calculateFunction(object, getValue<O>(luaState, 2, metatable.name).$1),
  );
  return 1;
});

import 'dart:ffi';

import 'package:dart_lua_ffi/generated_bindings.dart';
import 'package:target_classic/plugins/loaders/lua/utility/luaerrors.dart';

bool checkIndex(
  Pointer<lua_State> luaState,
  Iterable<String> keys,
  String index,
) {
  if (!keys.contains(index)) {
    luaError(luaState, "Attempt to index invalid key: ${index}");
    return false;
  }
  return true;
}

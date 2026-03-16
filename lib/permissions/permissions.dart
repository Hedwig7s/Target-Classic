import 'package:characters/characters.dart';
import 'package:logging/logging.dart';

mixin Permissions {
  final Set<String> _permissions = <String>{};
  final Set<String> _cache =
      <
        String
      >{}; // TODO: This should probably be a nested map rather than a flat set
  static Logger logger = Logger('Permissions');

  bool _validPermission(String permission) {
    if (permission.isEmpty) {
      return false;
    }
    if (permission.endsWith(".") || permission.endsWith("_")) {
      return false;
    }
    if (RegExp(r'^[a-zA-Z0-9._]+(?:\.\*)$').hasMatch(permission) == false) {
      return false;
    }
    return true;
  }

  void addPermission(String permission) {
    if (!_validPermission(permission)) {
      throw ArgumentError('Invalid permission: $permission');
    }
    _permissions.add(permission);
    _cache.add(permission);
  }

  void removePermission(String permission) {
    bool removed = _permissions.remove(permission);
    if (removed) {
      _cache
          .clear(); // TODO: Possibly find subset of _cache to clear instead of clearing everything
    }
  }

  bool _hasPermission(String permission) {
    if (_cache.contains(permission)) {
      return true;
    }
    if (_permissions.contains(permission)) {
      _cache.add(permission);
      return true;
    }
    return false;
  }

  bool hasPermission(String permission) {
    if (!_validPermission(permission)) {
      return false;
    }
    if (_hasPermission(permission)) {
      return true;
    }
    while (true) {
      permission =
          permission.characters.findLast('.'.characters)?.stringBefore ?? '';
      if (permission.isEmpty) {
        return false;
      }
      if (_hasPermission("$permission.*")) {
        return true;
      }
    }
  }

  Set<String> get permissions => _permissions.toSet();
}

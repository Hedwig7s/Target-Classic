import 'package:events_emitter/emitters/event_emitter.dart';
import 'package:target_classic/permissions/permissions.dart';
import 'package:target_classic/registries/namedregistry.dart';

class Role with Permissions implements Nameable<String> {
  @override
  final String name;
  @override
  final EventEmitter? emitter = null;

  final int powerLevel;

  Role({
    required this.name,
    required Set<String> permissions,
    required this.powerLevel,
  }) {
    for (final permission in permissions) {
      addPermission(permission);
    }
  }
}

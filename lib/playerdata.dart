import 'package:logging/logging.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:target_classic/context.dart';

class PlayerData {
  final DateTime firstJoin;
  final Set<String> knownIPs;
  static final Logger logger = Logger("PlayerData");
  final Database database;
  int id;
  final String currentIp;
  String name;
  DateTime lastJoin;
  PlayerData({
    required this.name,
    required this.firstJoin,
    DateTime? lastJoin,
    Set<String>? knownIPs,
    required this.database,
    required this.id,
    required this.currentIp,
  }) : lastJoin = lastJoin ?? DateTime.now(),
       knownIPs = knownIPs ?? {} {
    this.knownIPs.add(currentIp);
  }

  factory PlayerData.fromDatabase(
    ServerDatabases databases,
    String name,
    String currentIp,
  ) {
    final db = databases.playerData;
    final dataStatement = db.prepare(
      "SELECT * FROM player_data WHERE username = (?);",
    ); // FIXME: Should be cached
    final dataResult = dataStatement.select([name]);
    if (dataResult.isEmpty)
      return PlayerData.getDefault(databases, name, currentIp);
    if (dataResult.length > 1) {
      throw Exception(
        "Database index for name $name returned ${dataResult.length} results!",
      );
    }
    final dataRow = dataResult.first;
    final ipStatement = db.prepare(
      "SELECT * FROM player_ips WHERE player_id = (?);",
    ); // FIXME: Should also be cached
    final ipResults = ipStatement.select([dataRow["id"] as int]);
    final ips = <String>{};
    for (final row in ipResults) {
      ips.add(row["ip_address"]);
    }
    return PlayerData(
      name: name,
      firstJoin: DateTime.parse(dataRow["first_join"] as String),
      lastJoin: DateTime.parse(dataRow["last_join"] as String),
      knownIPs: ips,
      database: db,
      id: dataRow["id"] as int,
      currentIp: currentIp,
    );
  }

  factory PlayerData.getDefault(
    ServerDatabases databases,
    String name,
    String currentIp,
  ) => PlayerData(
    name: name,
    firstJoin: DateTime.now(),
    lastJoin: DateTime.now(),
    id: -1,
    database: databases.playerData,
    currentIp: currentIp,
  );
  void save() {
    // TODO: Consider adding periodic saving
    if (id == -1) {
      final statement = database.prepare("""
        INSERT INTO player_data (first_join, last_join, username)
        VALUES (?, ?, ?)
        RETURNING id;
        """); // TODO: Cache
      final ret = statement.select([
        firstJoin.toIso8601String(),
        lastJoin.toIso8601String(),
        name,
      ]);
      id = ret.first["id"] as int;
    } else {
      final statement = database.prepare("""
        UPDATE player_data
        SET first_join = (?), last_join = (?), username = (?)
        WHERE id = (?);
        """); // TODO: Cache
      statement.execute([
        firstJoin.toIso8601String(),
        lastJoin.toIso8601String(),
        name,
        id,
      ]);
    }
    final ipStatement = database.prepare("""
      INSERT INTO player_ips (player_id, ip_address, last_seen)
      VALUES (?, ?, ?)
      ON CONFLICT(player_id, ip_address) DO UPDATE SET
          last_seen = excluded.last_seen;
      """); // TODO: Oh yeah cache this too
    ipStatement.execute([id, currentIp, lastJoin.toIso8601String()]);
  }
}

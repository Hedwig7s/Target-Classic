import 'networking/protocol.dart';
import 'networking/protocols/7/protocol.dart';

final Map<int, Protocol> protocols = {7: Protocol7()};
const String CONFIG_FOLDER = "config";
const String WORLD_FOLDER = "worlds";

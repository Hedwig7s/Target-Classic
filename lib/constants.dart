import 'package:target_classic/networking/protocol.dart';
import 'package:target_classic/networking/protocols/7/protocol.dart';

final Map<int, Protocol> protocols = {7: Protocol7()};
const String CONFIG_FOLDER = "config";
const String WORLD_FOLDER = "worlds";
const String SOFTWARE_NAME = "Target Classic";
const String SOFTWARE_VERSION = "v0.2.0";

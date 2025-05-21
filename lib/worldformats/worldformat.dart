import '../world.dart';

abstract class WorldFormat {
  bool identify(List<int> data);
  WorldBuilder deserialize(List<int> data);
  List<int> serialize(World world);
  List<String> get extensions;
}

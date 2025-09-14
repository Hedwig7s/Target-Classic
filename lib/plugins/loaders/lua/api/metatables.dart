enum Metatables {
  Vector3("vector3"),
  EntityPosition("entityposition");

  const Metatables(name) : this.name = "mcclassic." + name;
  final String name;
}

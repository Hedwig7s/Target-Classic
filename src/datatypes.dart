import 'dart:math';

class Vector3<T extends num> {
  final T x;
  final T y;
  final T z;
  const Vector3(this.x, this.y, this.z);
  @override
  String toString() {
    return 'Vector3(x: $x, y: $y, z: $z)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Vector3) return false;
    return x == other.x && y == other.y && z == other.z;
  }

  Vector3 operator +(Vector3 other) {
    return Vector3(x + other.x, y + other.y, z + other.z);
  }

  Vector3 operator -(Vector3 other) {
    return Vector3(x - other.x, y - other.y, z - other.z);
  }

  Vector3 operator *(T scalar) {
    return Vector3(x * scalar, y * scalar, z * scalar);
  }

  Vector3 operator /(T scalar) {
    if (scalar == 0) {
      throw ArgumentError('Cannot divide by zero');
    }
    return Vector3(x / scalar, y / scalar, z / scalar);
  }

  num dot(Vector3 other) {
    return x * other.x + y * other.y + z * other.z;
  }

  double magnitude() {
    return sqrt(x * x + y * y + z * z);
  }

  Vector3 normalize() {
    double mag = magnitude();
    if (mag == 0) {
      throw ArgumentError('Cannot normalize a zero vector');
    }
    return Vector3(x / mag, y / mag, z / mag);
  }
}

typedef Vector3I = Vector3<int>;
typedef Vector3F = Vector3<double>;

class EntityPosition {
  final Vector3<double> position;
  double get x => position.x;
  double get y => position.y;
  double get z => position.z;
  final int yaw;
  final int pitch;

  EntityPosition(x, y, z, this.yaw, this.pitch)
    : position = Vector3(x.toT(), y.toT(), z.toT());
  EntityPosition.fromVector3({
    required this.position,
    required this.yaw,
    required this.pitch,
  });
}

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

  Vector3<int> toInt() {
    return Vector3<int>(x.toInt(), y.toInt(), z.toInt());
  }

  Vector3<double> toDouble() {
    return Vector3<double>(x.toDouble(), y.toDouble(), z.toDouble());
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
  final Vector3<double> vector;
  double get x => vector.x;
  double get y => vector.y;
  double get z => vector.z;
  final int yaw;
  final int pitch;

  EntityPosition(double x, double y, double z, this.yaw, this.pitch)
    : vector = Vector3<double>(x, y, z);
  EntityPosition.fromVector3({
    required this.vector,
    required this.yaw,
    required this.pitch,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EntityPosition &&
        this.vector == other.vector &&
        this.yaw == other.yaw &&
        this.pitch == other.pitch;
  }

  EntityPosition operator +(EntityPosition other) {
    return EntityPosition.fromVector3(
      vector: (vector + other.vector).toDouble(),
      yaw: yaw,
      pitch: pitch,
    );
  }

  EntityPosition operator -(EntityPosition other) {
    return EntityPosition.fromVector3(
      vector: (vector - other.vector).toDouble(),
      yaw: yaw,
      pitch: pitch,
    );
  }

  EntityPosition operator *(double scalar) {
    return EntityPosition.fromVector3(
      vector: (vector * scalar).toDouble(),
      yaw: yaw,
      pitch: pitch,
    );
  }

  EntityPosition operator /(double scalar) {
    if (scalar == 0) {
      throw ArgumentError('Cannot divide by zero');
    }
    return EntityPosition.fromVector3(
      vector: (vector / scalar).toDouble(),
      yaw: yaw,
      pitch: pitch,
    );
  }

  @override
  String toString() {
    return 'EntityPosition(position: $vector, yaw: $yaw, pitch: $pitch)';
  }
}

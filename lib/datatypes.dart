import 'dart:math' as math;

const PLAYER_HEIGHT_OFFSET = 1.59375;
const PLAYER_SELF_HEIGHT_OFFSET = -0.6875;

class Vector3<T extends num> {
  final T x;
  final T y;
  final T z;
  const Vector3(this.x, this.y, this.z);

  @override
  String toString() {
    return 'Vector3(x: $x, y: $y, z: $z)';
  }

  Map<String, T> toMap() {
    return {"x": x, "y": y, "z": z};
  }

  Vector3<int> toInt() {
    return Vector3<int>(x.toInt(), y.toInt(), z.toInt());
  }

  Vector3<double> toDouble() {
    return Vector3<double>(x.toDouble(), y.toDouble(), z.toDouble());
  }

  Vector3<double> toClientCoordinates([bool isSelf = false]) {
    return Vector3F(
      x.toDouble(),
      y + PLAYER_HEIGHT_OFFSET + (isSelf ? PLAYER_SELF_HEIGHT_OFFSET : 0),
      z.toDouble(),
    );
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

  Vector3 operator *(num scalar) {
    if (scalar is int && this is Vector3I) {
      return Vector3I(
        (x * scalar).toInt(),
        (y * scalar).toInt(),
        (z * scalar).toInt(),
      );
    } else {
      return Vector3F(
        (x * scalar).toDouble(),
        (y * scalar).toDouble(),
        (z * scalar).toDouble(),
      );
    }
  }

  Vector3F operator /(num scalar) {
    if (scalar == 0) {
      throw ArgumentError('Cannot divide by zero');
    }
    return Vector3F(x / scalar, y / scalar, z / scalar);
  }

  Vector3I operator ~/(int scalar) {
    if (scalar == 0) {
      throw ArgumentError('Cannot divide by zero');
    }
    return Vector3I(
      (x / scalar).floor(),
      (y / scalar).floor(),
      (z / scalar).floor(),
    );
  }

  Vector3F operator %(num scalar) {
    return Vector3F(
      (x % scalar).toDouble(),
      (y % scalar).toDouble(),
      (z % scalar).toDouble(),
    );
  }

  Vector3 pow(num scalar) {
    return Vector3(
      math.pow(x, scalar),
      math.pow(y, scalar),
      math.pow(z, scalar),
    );
  }

  num dot(Vector3 other) {
    return x * other.x + y * other.y + z * other.z;
  }

  double magnitude() {
    return math.sqrt(x * x + y * y + z * z);
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

  EntityPosition(double x, double y, double z, int yaw, int pitch)
    : vector = Vector3<double>(x, y, z),
      yaw = yaw % 193,
      pitch = pitch % 256;
  EntityPosition.fromVector3({
    required this.vector,
    required int yaw,
    required int pitch,
  }) : yaw = yaw % 193,
       pitch = pitch % 256;

  Map<String, dynamic> toMap() {
    return {
      "x": x,
      "y": y,
      "z": z,
      "vector": vector,
      "yaw": yaw,
      "pitch": pitch,
    };
  }

  EntityPosition toClientCoordinates([bool isSelf = false]) {
    return EntityPosition.fromVector3(
      vector: vector.toClientCoordinates(isSelf),
      yaw: yaw,
      pitch: pitch,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EntityPosition &&
        vector == other.vector &&
        yaw == other.yaw &&
        pitch == other.pitch;
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

  EntityPosition operator ~/(int scalar) {
    if (scalar == 0) {
      throw ArgumentError('Cannot divide by zero');
    }
    return EntityPosition.fromVector3(
      vector: (vector ~/ scalar).toDouble(),
      yaw: yaw,
      pitch: pitch,
    );
  }

  @override
  String toString() {
    return 'EntityPosition(position: $vector, yaw: $yaw, pitch: $pitch)';
  }
}

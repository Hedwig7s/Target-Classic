require("shared")

local record Vector3
    interface Vector3<T> is DartObject
        x: T
        y: T
        z: T
        -- Converts the Vector3 to an integer Vector3
        toInt: function(self): Vector3<integer>
        -- Converts the Vector3 to a number Vector3, rounding down if necessary
        toDouble: function(self): Vector3<number>
        metamethod __add: function(self, other: Vector3): Vector3
        metamethod __sub: function(self, other: Vector3): Vector3
        metamethod __mod: function(self, scalar: number): Vector3<number>
        metamethod __mul: function(self, scalar: number): Vector3
        metamethod __div: function(self, scalar: number): Vector3<number>
        metamethod __idiv: function(self, scalar: integer): Vector3<integer>
        metamethod __pow: function(self, scalar: number): Vector3
        metamethod __len: function(self): number
        dot: function(self, other: Vector3): Vector3
        magnitude: function(self): number
    end
    -- Creates a new Vector3 for integers
    newInt: function(x: integer, y: integer, z: integer): Vector3<integer>
    -- Creates a new Vector3 for numbers
    newDouble: function(x: number, y: number, z: number): Vector3<number>
end

return Vector3
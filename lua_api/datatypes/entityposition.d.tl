require("shared")
local type Vector3 = require("datatypes.vector3").Vector3

local record EntityPosition
    interface EntityPosition is DartObject
        x: number
        y: number
        z: number
        yaw: integer
        pitch: integer
        vector: Vector3<number>
        metamethod __add: function(self, other: EntityPosition): EntityPosition
        metamethod __sub: function(self, other: EntityPosition): EntityPosition
        metamethod __mul: function(self, scalar: number): EntityPosition
        metamethod __div: function(self, scalar: number): EntityPosition
        metamethod __idiv: function(self, scalar: integer): EntityPosition
    end
    -- Creates an EntityPosition
    new: function(x: number, y: number, z: number, yaw: integer, pitch: number)
    -- Creates an EntityPosition from a Vector3
    fromVector3: function(vector3: Vector3<number>, yaw: integer, pitch: number)
end

return EntityPosition
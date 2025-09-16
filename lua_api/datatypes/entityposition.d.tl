local type Vector3 = require("datatypes.vector3").Vector3

local record EntityPosition
    interface EntityPosition
        x: number
        y: number
        z: number
        yaw: integer
        pitch: integer
        vector: Vector3<number>
    end
    -- Creates an EntityPosition
    new: function(x: number, y: number, z: number, yaw: integer, pitch: number)
end

return EntityPosition
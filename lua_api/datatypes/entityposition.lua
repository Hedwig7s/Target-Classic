---@meta EntityPosition

---@class EntityPosition: DartObject, { 
---    x: number, 
---    y: number, 
---    z: number, 
---    yaw: integer,
---    pitch: integer,
---    vector: Vector3<number>}
---@operator add(EntityPosition): EntityPosition
---@operator sub(EntityPosition): EntityPosition
---@operator mul(number): EntityPosition
---@operator div(number): EntityPosition
---@operator idiv(integer): EntityPosition
local EntityPosition = {}

---@class Classic.DataTypes.EntityPosition
local EntityPosition = {
    ---Creates an EntityPosition
    ---@param x number
    ---@param y number
    ---@param z number
    ---@param yaw integer
    ---@param pitch integer
    ---@return EntityPosition
    new = function (x, y, z, yaw, pitch) end,
    ---Creates an EntityPosition from a Vector3
    ---@param vector3 Vector3<number>
    ---@param yaw integer
    ---@param pitch integer
    ---@return EntityPosition
    fromVector3 = function(vector3, yaw, pitch) end,
}


Classic.DataTypes.EntityPosition = EntityPosition
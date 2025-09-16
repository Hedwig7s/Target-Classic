---@meta Vector3

---@generic T : number|integer
---@alias EntityPosition { 
---    x: number, 
---    y: number, 
---    z: number, 
---    yaw: integer,
---    pitch: integer,
---    vector: Vector3<number>,
---    toInt: fun(self: Vector3<T>): (Vector3<integer>)}


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

}


Classic.DataTypes.EntityPosition = EntityPosition
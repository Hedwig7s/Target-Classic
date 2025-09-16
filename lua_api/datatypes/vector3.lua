---@meta Vector3

---@generic T : number|integer
---@alias Vector3<T> { 
---    x: T, 
---    y: T, 
---    z: T, 
---    toDouble: fun(self: Vector3<T>): (Vector3<number>),
---    toInt: fun(self: Vector3<T>): (Vector3<integer>)}


---@class Classic.DataTypes.Vector3
local Vector3 = {
    ---Creates a Vector3 for integers
    ---@param x integer
    ---@param y integer
    ---@param z integer
    ---@return Vector3<integer>
    newInt = function (x, y, z) end,
    ---Creates a Vector3 for numbers
    ---@param x number
    ---@param y number
    ---@param z number
    ---@return Vector3<number>
    newDouble = function (x, y, z) end
}


Classic.DataTypes.Vector3 = Vector3
---@meta Vector3

---@generic T : number|integer
---@alias IVector3<T> { 
---    x: T, 
---    y: T, 
---    z: T, 
---    toDouble: fun(self: IVector3<T>): IVector3<number>,
---    toInt: fun(self: IVector3<T>): IVector3<integer> }

---@class DataTypes.Vector3
local Vector3 = {
    ---@param x integer
    ---@param y integer
    ---@param z integer
    ---@return IVector3<integer>
    newInt = function (x, y, z) end,
    ---@param x number
    ---@param y number
    ---@param z number
    ---@return IVector3<number>
    newFloat = function (x, y, z) end
}


DataTypes.Vector3 = Vector3
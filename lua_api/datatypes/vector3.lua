---@meta Vector3

---@generic T : number|integer
---@alias IVector3<T> { 
---    x: T, 
---    y: T, 
---    z: T, 
---    toDouble: fun(self: IVector3<T>): IVector3<number>,
---    toInt: fun(self: IVector3<T>): IVector3<integer>}


---@class Classic.DataTypes.Vector3
local Vector3 = {
    ---Creates a Vector3 for integers
    ---@param x integer
    ---@param y integer
    ---@param z integer
    ---@return IVector3<integer>
    newInt = function (x, y, z) end,
    ---Creates a Vector3 for numbers
    ---@param x number
    ---@param y number
    ---@param z number
    ---@return IVector3<number>
    newFloat = function (x, y, z) end
}


Classic.DataTypes.Vector3 = Vector3
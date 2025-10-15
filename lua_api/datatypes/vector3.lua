---@meta Vector3

---@generic T: number|integer
---@class Vector3: DartObject, { 
---    x: T, 
---    y: T, 
---    z: T}
---@operator add(Vector3<number|integer>): Vector3<number|integer>
---@operator sub(Vector3<number|integer>): Vector3<number|integer>
---@operator mod(number): Vector3<number>
---@operator mul(number): Vector3<number|integer>
---@operator div(number): Vector3<number>
---@operator idiv(integer): Vector3<integer>
---@operator pow(number): Vector3<number|integer>
---@operator len: number
local Vector3 = {}

---@param self Vector3<number|integer>
---@param other Vector3<number|integer>
---@return Vector3<number|integer>
function Vector3:dot(other) end

---@param self Vector3<number|integer>
---@return number
function Vector3:magnitude() end

---@param self Vector3<string|integer>
---@return Vector3<number>
---Converts the Vector3 to a number Vector3
function Vector3:toDouble() end

---@param self Vector3<string|integer>
---@return Vector3<integer>
---Converts the Vector3 to an integer Vector3, rounding down if necessary
function Vector3:toInt() end

---@class Classic.DataTypes.Vector3
local CVector3 = {
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


Classic.DataTypes.Vector3 = CVector3
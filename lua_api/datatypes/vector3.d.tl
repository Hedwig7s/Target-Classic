local record Vector3
    interface Vector3<T>
        x: T
        y: T
        z: T
        -- Converts the Vector3 to an integer Vector3, rounding down if necessary
        toInt: function(self): Vector3<integer>
        -- Converts the Vector3 to a number Vector3, rounding down if necessary
        toDouble: function(self): Vector3<number>
    end
    -- Creates a new Vector3 for integers
    newInt: function(x: integer, y: integer, z: integer): Vector3<integer>
    -- Creates a new Vector3 for numbers
    newDouble: function(x: number, y: number, z: number): Vector3<number>
end

return Vector3
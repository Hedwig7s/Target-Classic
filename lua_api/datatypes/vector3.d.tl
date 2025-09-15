local record Vector3
    interface IVector3<T>
        x: T
        y: T
        z: T
        -- Converts the Vector3 to an integer Vector3, rounding down if necessary
        toInt: function(): IVector3<integer>
        -- Converts the Vector3 to a number Vector3, rounding down if necessary
        toDouble: function(): IVector3<number>
    end

    record CVector3
        -- Creates a new Vector3 for integers
        newInt: function(x: integer, y: integer, z: integer): IVector3<integer>
        -- Creates a new Vector3 for numbers
        newFloat: function(x: number, y: number, z: number): IVector3<number>
    end
end

return Vector3
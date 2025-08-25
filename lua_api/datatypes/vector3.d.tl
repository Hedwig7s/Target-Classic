local record Vector3
    interface IVector3<T>
        x: T
        y: T
        z: T
        toInt: function(): IVector3<integer>
        toDouble: function(): IVector3<number>
    end

    record CVector3
        new: function<T>(x: T, y: T, z: T): IVector3<T>
    end
end

return Vector3
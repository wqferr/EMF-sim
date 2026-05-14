local vec = require "vec"

local interface Row is {Vec3}
    globalOffset: Vec3
end

local interface Layer is {Row}
    globalOffset: Vec3

    closestNode: function(self, x: number, y: number, z: number): {integer, integer}
end

global interface Field
    values: {Layer}
    dimensions: Vec3
    granularity: number

    at: function(self, x: number, y: number, z: number): Vec
end

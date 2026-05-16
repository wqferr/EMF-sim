local vec = require "vec"
local field = require "field"

describe("Vector fields", function()
    it("can set points", function()
        local f = field(vec(1, 1, 1), 0.25)
        local p = vec(0.5, 0.25, 0.25)
        local expected = vec(1, 0, 0)
        f:setNext(p, expected)
        f:commit()

        local actual = f:value(p)
        local diff = expected - actual
        assert.is.near(0, diff.mag, 0.001)
    end)

    describe("can interpolate", function()
        it("in one dimension", function()
            local f = field(vec(1, 1, 1), 0.5)
            local p1 = vec(0, 0, 0)
            local p2 = vec(0.5, 0, 0)
            local v1 = vec(-math.sqrt(2), math.sqrt(3), 1)
            local v2 = vec(math.sqrt(2), 3, 2)
            local t = 0.5
            local lerpP = vec.lerp(p1, p2, t)
            local expected = vec.lerp(v1, v2, t)

            f:setNext(p1, v1)
            f:setNext(p2, v2)
            f:commit()

            local actual = f:value(lerpP)
            local diff = expected - actual
            assert.is.near(0, diff.mag, 0.001)
        end)
    end)
end)

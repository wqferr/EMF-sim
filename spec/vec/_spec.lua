local vec = require "vec"

describe(
    "Vecs",
    function()
        describe("should know their length", function()
            it("when created with .zeros", function()
                local v = vec.zeros(3)
                assert.are.equal(3, #v)
            end)

            it("when created with vararg", function()
                local v = vec(1, 2, nil, 4, 1)
                assert.are.equal(5, #v)
            end)

            it("when created with .ones", function()
                local v = vec.ones(1000)
                assert.are.equal(1000, #v)
            end)

            it("when created from an array", function()
                local v = vec.fromarray{0, 3}
                assert.are.equal(2, #v)
            end)
        end)

        describe("can use indices", function()
            it("for reading", function()
                local v = vec(0.5, 1.5, 2.5, 3.5, 4.5)
                for i = 1, #v do
                    assert.are.equal(i - 0.5, v[i])
                end
            end)

            it("for writing", function()
                local v = vec.zeros(3)
                v[1] = 2
                v[2] = 4
                v[3] = 6

                for i = 1, #v do
                    assert.are.equal(2*i, v[i])
                end
            end)
        end)

        describe("can use named coordinates", function()
            it("for reading", function()
                local v = vec(4, 3, 2, 1)

                assert.are.equal(4, v.x)
                assert.are.equal(3, v.y)
                assert.are.equal(2, v.z)
                assert.are.equal(1, v.w)
            end)

            it("for writing", function()
                local v = vec.zeros(4)
                v.x = -1
                v.y = -2
                v.z = -3
                v.w = -4

                assert.are.equal(-1, v[1])
                assert.are.equal(-2, v[2])
                assert.are.equal(-3, v[3])
                assert.are.equal(-4, v[4])
            end)
        end)

        it("can add with another Vec", function()
            local v1 = vec(5, -1, 0, 2, 10)
            local v2 = vec(1, 0, -3, -2, 5, 7)
            local v3 = v1 + v2
            assert.are.equal(#v2, #v3)
            assert.are.equal(6, v3.x)
            assert.are.equal(-1, v3.y)
            assert.are.equal(-3, v3.z)
            assert.are.equal(0, v3.w)
            assert.are.equal(15, v3[5])
            assert.are.equal(7, v3[6])
        end)

        it("can subtract with another Vec", function()
            local v1 = vec(5, -1, 0, 2, 10)
            local v2 = vec(1, 0, -3, -2, 5, 7)
            local v3 = v1 - v2

            assert.are.equal(#v2, #v3)
            assert.are.equal(4, v3.x)
            assert.are.equal(-1, v3.y)
            assert.are.equal(3, v3.z)
            assert.are.equal(4, v3.w)
            assert.are.equal(5, v3[5])
            assert.are.equal(-7, v3[6])
        end)

        describe("can scale", function()
            it("with the dedicated function", function()
                local u = vec(-1, 0, 3)
                local scalar = 3
                local v = vec.scale(u, scalar)
                for i = 1, #u do
                    assert.are.equal(u[i] * scalar, v[i])
                end
            end)

            it("with __mul on the left", function()
                local u = vec(-1, 0, 3)
                local scalar = 3
                local v = u * scalar
                for i = 1, #u do
                    assert.are.equal(u[i] * scalar, v[i])
                end
            end)

            it("with __mul on the right", function()
                local u = vec(-1, 0, 3)
                local scalar = 3
                local v = scalar * u
                for i = 1, #u do
                    assert.are.equal(u[i] * scalar, v[i])
                end
            end)
        end)

        it("frompolar constructs properly", function()
            local mag = 5
            local v = vec.frompolar(mag, 16/3 * math.pi)
            local expected = mag * vec(-1/2, -math.sqrt(3)/2)
            local diff = expected - v
            assert.is.near(0, diff.mag, 0.0001)
        end)

        it("fromspherical constructs properly", function()
            local mag = 3
            local v = vec.fromspherical(mag, math.pi/4, math.pi/3)
            local expected = vec(1.0607, 1.837, 2.1213)
            local diff = expected - v
            assert.is.near(0, diff.mag, 0.001)
        end)

        it("fromcylindrical constructs properly", function()
            local r = 10
            local v = vec.fromcylindrical(r, math.pi/6, 3)
            local expected = vec(r * math.sqrt(3)/2, r/2, 3)
            local diff = expected - v
            assert.is.near(0, diff.mag, 0.001)
        end)

        it("cross product calculates correctly", function()
            local v1 = vec(1, 2, 3)
            local v2 = vec(1, 5, 7)
            local expected = vec(-1, -4, 3)
            local result = v1^v2
            local diff = expected - result
            assert.is.near(0, diff.mag, 0.001)
        end)
    end
)

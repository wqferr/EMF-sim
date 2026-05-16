local vec = require "vec"
local md = require "miscdrawer"

local myVec: Vec3
local screenCenter: Vec2
local miscDrawer: MiscDrawer
function love.load(args: {string}, unfiltered_args: {string})
    local _, _ = args, unfiltered_args
    global DEBUG_PRINT = true
    myVec = vec(1, 0, 0)
    print(myVec)
    screenCenter = vec(love.graphics.getDimensions())
    miscDrawer = md()
end

-- function love.update(dt: number)
--     myVec = vec.rotate(myVec, vec.posz, math.deg(60) * dt) as Vec3
-- end

-- function love.draw()
--     miscDrawer:drawVecNormalized(screenCenter, myVec)
-- end

local vec = require "vec"
local md = require "miscdrawer"
local inspect = require "inspect"

local myVec: Vec3
local screenCenter: Vec2
local miscDrawer: MiscDrawer
function love.load(args: {string}, unfiltered_args: {string})
    local _, _ = args, unfiltered_args
    global DEBUG_PRINT = true
    myVec = vec(1, 0, 0)
    screenCenter = vec(love.graphics.getDimensions()) * 0.5
    screenCenter = screenCenter + vec.ones(2, 0.5) as Vec2
    miscDrawer = md()
end

function love.keypressed(key: love.keyboard.KeyConstant, isRepeat: boolean)
    local _ = isRepeat
    if key == "q" then
        love.event.quit()
    end
end

function love.update(dt: number)
    if love.keyboard.isDown "space" then
        myVec = vec.rotate(myVec, vec.posz, dt)
    end
    if love.keyboard.isDown "up" then
        myVec.z = myVec.z + dt*10
    elseif love.keyboard.isDown "down" then
        myVec.z = myVec.z - dt*10
    end
end

function love.draw()
    miscDrawer:drawVecNormalized(screenCenter, myVec)
    -- love.graphics.line(screenCenter.x, screenCenter.y, 0, 0)
end

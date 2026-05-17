local vec = require "vec"
local field = require "field"
local md = require "miscdrawer"

local electricField: Field
local screenCenter: Vec2
local miscDrawer: MiscDrawer
function love.load(args: {string}, unfiltered_args: {string})
    local _, _ = args, unfiltered_args
    global DEBUG_PRINT = true
    electricField = field(vec.ones(3, 2) as Vec3, 0.125)
    screenCenter = vec(love.graphics.getDimensions()) * 0.5
    screenCenter = screenCenter + vec.ones(2, 0.5) as Vec2
    miscDrawer = md()
    miscDrawer.fieldConfig.screenMin = vec(0, 0)
    miscDrawer.fieldConfig.screenMax = vec(love.graphics.getDimensions())
end

function love.keypressed(key: love.keyboard.KeyConstant, isRepeat: boolean)
    local _ = isRepeat
    if key == "q" then
        love.event.quit()
    end
end

function love.update(dt: number)
end

function love.draw()
    miscDrawer:drawVecFieldNormalized(electricField, 0.5, {color={0.3, 1, 1}})
end

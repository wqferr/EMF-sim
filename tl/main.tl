local vec = require "vec"
local field = require "field"
local md = require "miscdrawer"

local updateElectricField: function(Vec3)

local electricField: Field
local mouseCharge: number
local miscDrawer: MiscDrawer
local mouseZ: number
local cumDt: number
local sparcity = 25
local scale = 10
function love.load(args: {string}, unfiltered_args: {string})
    local _, _ = args, unfiltered_args
    local dimensions = vec(love.graphics.getDimensions())
    mouseCharge = 100
    cumDt = 0
    mouseZ = 0.5
    electricField = field(
        vec(
            dimensions.x / scale,
            dimensions.y / scale,
            1
        ),
        sparcity / scale
    )
    miscDrawer = md()
    miscDrawer.vecConfig.xYMaxRadius = 25
    miscDrawer.fieldConfig.screenMin = vec(0, 0)
    miscDrawer.fieldConfig.screenMax = dimensions
    miscDrawer.fieldConfig.nPoints = {10, 10}
    miscDrawer.fieldConfig.minP = vec(0, 0)
    miscDrawer.fieldConfig.maxP = miscDrawer.fieldConfig.screenMax / scale
end

function love.keypressed(key: love.keyboard.KeyConstant, isRepeat: boolean)
    local _ = isRepeat
    if key == "q" then
        love.event.quit()
    end
end

local updateFreq = 0.025
function love.update(dt: number)
    cumDt = cumDt + dt
    if cumDt >= updateFreq then
        local mouseXY = vec(love.mouse.getPosition()) / scale
        updateElectricField(vec(mouseXY.x, mouseXY.y, mouseZ))
        electricField:commit()
        cumDt = 0
    end
end

function love.wheelmoved(_dx: number, dy: number)
    mouseZ = mouseZ + dy * 0.05
end

function love.draw()
    for x = 0, electricField.dimensions.x, electricField.granularity.x do
        local vx = scale*x
        for y = 0, electricField.dimensions.y, electricField.granularity.y do
            local vy = scale*y
            -- love.graphics.line(0, vy, vx, vy)
            -- love.graphics.line(vx, 0, vx, vy)
        end
    end
    miscDrawer:drawVecFieldNormalized(
        electricField,
        0.5,
        {
            nPoints = {
                math.floor(electricField:numCells(1)),
                math.floor(electricField:numCells(2))
            },
            color = {1, 1, 0.4},
        }
    )
end

function updateElectricField(mousePosWithZ: Vec3)
    field.contribute(
        electricField,
        function(p: Vec3, _fieldValue: Vec3): Vec3
            local diff = p - mousePosWithZ
            return diff.normalized * mouseCharge / diff.magsqr
        end
    )
end

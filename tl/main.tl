local vec = require "vec"
local field = require "field"
local particle = require "particle"
local md = require "miscdrawer"

local updateElectricField: function(dt: number)
local updateMagneticField: function(dt: number)

local updateParticles: function(dt: number)

local electricField: Field
local magneticField: Field
local freeCurrentDensityField: Field

local particles: {Particle}

local mouseForceIntensity: number

local start: boolean

local miscDrawer: MiscDrawer
local cumulativeDt: number
local sparcity = 50
local fieldToScreenConversionFactor = 10
local fieldsGridSize: Vec3
function love.load(args: {string}, unfiltered_args: {string})
    local _, _ = args, unfiltered_args

    start = false

    local dimensions = vec(love.graphics.getDimensions())
    local screenCenter = dimensions / 2
    cumulativeDt = 0
    fieldsGridSize = vec(
        dimensions.x / fieldToScreenConversionFactor,
        dimensions.y / fieldToScreenConversionFactor,
        1
    )

    local newField = function(): Field
        return field(fieldsGridSize, sparcity / fieldToScreenConversionFactor)
    end
    electricField = newField()
    magneticField = newField()
    freeCurrentDensityField = newField()

    mouseForceIntensity = 600

    particles = {
        particle.new {
            mass = 1000,
            charge = 50,
            radius = electricField.granularity.x,
            position = vec(screenCenter.x, dimensions.y * 0.9, 0.5) / fieldToScreenConversionFactor,
            velocity = vec(5, 0, 2)
        },
        particle.new {
            mass = 200,
            charge = 1,
            radius = electricField.granularity.x / 2,
            position = vec(screenCenter.x, dimensions.y * 0.1, 0.5) / fieldToScreenConversionFactor,
            velocity = vec(0, 0, 0)
        }
    }

    miscDrawer = md()
    miscDrawer.vecConfig.xYMaxRadius = 25
    miscDrawer.fieldConfig.screenMin = vec(0, 0)
    miscDrawer.fieldConfig.screenMax = dimensions
    miscDrawer.fieldConfig.nPoints = {10, 10}
    miscDrawer.fieldConfig.minP = vec(0, 0)
    miscDrawer.fieldConfig.maxP = miscDrawer.fieldConfig.screenMax / fieldToScreenConversionFactor
end

function love.keypressed(key: love.keyboard.KeyConstant, isRepeat: boolean)
    local _ = isRepeat
    if key == "q" then
        love.event.quit()
    elseif key == "space" then
        start = true
    end
end

local updateInterval = 1 / 60
function love.update(dt: number)
    cumulativeDt = cumulativeDt + dt
    if cumulativeDt >= updateInterval then
        if start then
            updateParticles(cumulativeDt)
            updateMagneticField(cumulativeDt)
            updateElectricField(cumulativeDt)
        end
        cumulativeDt = 0
    end
end

local function drawField(f: Field, color: {number, number, number})
    miscDrawer:drawVecFieldNormalized(
        f,
        0.5,
        {
            nPoints = {
                f:numCells(1),
                f:numCells(2)
            },
            color = color,
        }
    )
end

function love.draw()
    for _, p in ipairs(particles) do
        local pos = p.position * fieldToScreenConversionFactor
        love.graphics.setColor({1, 1, 1})
        love.graphics.circle("line", pos.x, pos.y, p.radius * fieldToScreenConversionFactor)
    end
    drawField(electricField, {1, 1, 0.4})
    drawField(magneticField, {0.4, 1, 1})
end

local function applyMouseForce(p: Particle)
    do
        return
    end
    local mousePos = vec(love.mouse.getPosition()) / fieldToScreenConversionFactor
    local mousePos3D = vec(mousePos.x, mousePos.y, 0.5)
    local displacement = mousePos3D - p.position
    if displacement.mag < p.radius then
        return
    end
    local direction = (displacement).normalized

    particle.addForce(p, direction * mouseForceIntensity)
end

local function applyReturnalForce(p: Particle)
    local screenCenter = vec(love.graphics.getDimensions()) / (2*fieldToScreenConversionFactor)
    local displacement = vec(screenCenter.x, screenCenter.y, 0.5) - p.position
    local direction = displacement.normalized
    direction.y = 0
    particle.addForce(p, direction * displacement.mag * 100)
end

function updateParticles(dt: number)
    for _, p in ipairs(particles) do
        particle.addForce(p, electricField:value(p.position))
        particle.step(p, dt)
    end
    applyMouseForce(particles[1])
    applyReturnalForce(particles[1])
end

local function roundDownToGridPoint(f: Field, p: Vec3): Vec3
    local gran = f.granularity
    return vec(
        gran.x * math.floor(p.x / gran.x),
        gran.y * math.floor(p.y / gran.y),
        gran.z * math.floor(p.z / gran.z)
    )
end

local function roundUpToGridPoint(f: Field, p: Vec3): Vec3
    return roundDownToGridPoint(f, p + 0.5*f.granularity)
end

local function applyCurrentForPart(part: Particle)
    local diag = vec(part.radius, part.radius, part.radius)

    local minP = roundDownToGridPoint(freeCurrentDensityField, part.position - diag)
    local maxP = roundUpToGridPoint(freeCurrentDensityField, part.position + diag)

    local radSqr = part.radius * part.radius

    -- Revisit this, might need to do some trig for the cross section area of the sphere
    local partCurrentDensity = part.charge / part.radius
    for x = minP.x, maxP.x, freeCurrentDensityField.granularity.x do
        for y = minP.y, maxP.y, freeCurrentDensityField.granularity.y do
            for z = minP.z, maxP.z, freeCurrentDensityField.granularity.z do
                local p = vec(x, y, z)
                local diff = part.position - p
                if diff.magsqr <= radSqr then
                    freeCurrentDensityField:add(p, partCurrentDensity * part.velocity)
                end
            end
        end
    end
end

function updateElectricField(dt: number)
    electricField:globalSet(
        function(p: Vec3, _fieldValue: Vec3): Vec3
            local total = vec(0, 0, 0)
            for _, part in ipairs(particles) do
                local diff = p - part.position
                if diff.mag > part.radius then
                    total = total + diff.normalized * part.charge / diff.magsqr
                end
            end
            return total
        end
    )
    for _, part in ipairs(particles) do
        applyCurrentForPart(part)
    end
    freeCurrentDensityField:commit()
    electricField:globalSet(
        function(p: Vec3, fieldValue: Vec3): Vec3
            -- TODO permeability constant and the other one
            return fieldValue + dt*(magneticField:curl(p) - freeCurrentDensityField:value(p))
        end
    )
    electricField:commit()
end

function updateMagneticField(dt: number)
    -- magneticField:copyState()
    magneticField:globalSet(
        function(p: Vec3, fieldValue: Vec3): Vec3
            return fieldValue - electricField:curl(p) * dt
        end
    )
    magneticField:commit()
end

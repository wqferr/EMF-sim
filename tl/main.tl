local vec = require "vec"
local field = require "field"
require "particle"
local md = require "miscdrawer"

local updateElectricFields: function()
local updateMagneticField: function(number)
local updateCurrentFields: function(dt: number): Vec3
local commitFields: function()

local updateParticles: function(dt: number)

local electricFieldNoParticles: Field
local electricFieldOnlyParticles: Field
local electricFieldTotal: Field
local magneticField: Field
local freeCurrentDensityField: Field
local inducedCurrentField: Field

local particles: {Particle}

local miscDrawer: MiscDrawer
local cumDt: number
local sparcity = 50
local fieldToScreenConversionFactor = 10
local fieldsGridSize: Vec3
function love.load(args: {string}, unfiltered_args: {string})
    local _, _ = args, unfiltered_args
    local dimensions = vec(love.graphics.getDimensions())
    local screenCenter = dimensions / 2
    cumDt = 0
    fieldsGridSize = vec(
        dimensions.x / fieldToScreenConversionFactor,
        dimensions.y / fieldToScreenConversionFactor,
        1
    )

    local newField = function(): Field
        return field(fieldsGridSize, sparcity / fieldToScreenConversionFactor)
    end
    electricFieldNoParticles = newField()
    electricFieldOnlyParticles = newField()
    electricFieldTotal = newField()
    magneticField = newField()
    inducedCurrentField = newField()
    freeCurrentDensityField = newField()

    particles = {
        {
            mass = 1,
            charge = 100,
            radius = 3 * electricFieldNoParticles.granularity.x,
            position = vec(screenCenter.x, screenCenter.y, 0.5) / fieldToScreenConversionFactor,
            velocity = vec(20, 0, 0)
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
    end
end

local updateInterval = 1 / 60
function love.update(dt: number)
    cumDt = cumDt + dt
    if cumDt >= updateInterval then
        updateParticles(cumDt)
        updateMagneticField(cumDt)
        updateElectricFields()
        updateCurrentFields(cumDt)
        commitFields()
        cumDt = 0
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
    for _, particle in ipairs(particles) do
        local pos = particle.position * fieldToScreenConversionFactor
        love.graphics.setColor({1, 1, 1})
        love.graphics.circle("line", pos.x, pos.y, particle.radius)
    end
    drawField(electricFieldTotal, {1, 1, 0.4})
    drawField(magneticField, {0.4, 1, 1})
end

function updateParticles(dt: number)
    for _, particle in ipairs(particles) do
        particle.position = particle.position + dt*particle.velocity
        particle.velocity = particle.velocity + dt*electricFieldTotal:value(particle.position)
    end
end

function updateElectricFields()
    electricFieldOnlyParticles:globalSet(
        function(p: Vec3, _fieldValue: Vec3): Vec3
            local total = vec(0, 0, 0)
            for _, particle in ipairs(particles) do
                local diff = p - particle.position
                if diff.magsqr > 0 then
                    total = total + diff.normalized * particle.charge / diff.magsqr
                end
            end
            return total
        end
    )
    electricFieldTotal:globalSet(
        function(p: Vec3, _): Vec3
            return electricFieldNoParticles:value(p) + electricFieldOnlyParticles:value(p)
        end
    )
end

function updateMagneticField(dt: number)
    magneticField:globalSet(
        function(p: Vec3, fieldValue: Vec3): Vec3
            return fieldValue - electricFieldNoParticles:curl(p) * dt
        end
    )
end

local function roundDownToGridPoint(f: Field, p: Vec3): Vec3
    local gran = f.granularity
    return vec(
        math.floor(p.x / gran.x),
        math.floor(p.y / gran.y),
        math.floor(p.z / gran.z)
    )
end

local function roundUpToGridPoint(f: Field, p: Vec3): Vec3
    return roundDownToGridPoint(f, p + 0.5*f.granularity)
end

local function applyCurrentForParticle(particle: Particle)
    local diag = vec(particle.radius, particle.radius, particle.radius)

    local minP = roundDownToGridPoint(freeCurrentDensityField, particle.position - diag)
    local maxP = roundUpToGridPoint(freeCurrentDensityField, particle.position + diag)

    local radSqr = particle.radius * particle.radius

    -- Revisit this, might need to do some trig for the cross section area of the sphere
    local particleCurrentDensity = particle.charge / particle.radius
    for x = minP.x, maxP.x, freeCurrentDensityField.granularity.x do
        for y = minP.y, maxP.y, freeCurrentDensityField.granularity.y do
            for z = minP.z, maxP.z, freeCurrentDensityField.granularity.z do
                local p = vec(x, y, z)
                local diff = particle.position - p
                if diff.magsqr <= radSqr then
                    freeCurrentDensityField:add(p, particleCurrentDensity * particle.velocity)
                end
            end
        end
    end
end

function updateCurrentFields(dt: number)
    inducedCurrentField:globalSet(
        function(p: Vec3, fieldValue: Vec3): Vec3
            return fieldValue + dt*(magneticField:curl(p) - freeCurrentDensityField:value(p))
        end
    )
    for _, particle in ipairs(particles) do
        applyCurrentForParticle(particle)
    end
end

function commitFields()
    magneticField:commit()
    electricFieldNoParticles:commit()
    electricFieldOnlyParticles:commit()
    electricFieldTotal:commit()
    inducedCurrentField:commit()
    freeCurrentDensityField:commit()
end

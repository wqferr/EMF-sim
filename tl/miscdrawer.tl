local vec = require "vec"
local _field = require "field"

local lg = love.graphics
global record MiscDrawer
    vecConfig: VecDrawConfig
    fieldConfig: FieldDrawConfig
end

local md_mt: metatable<MiscDrawer> = {__index = MiscDrawer}

local record VecDrawConfig
    lineThickness: number
    intoOutofMarkerMaxRadius: number
    xYMaxRadius: number
    minNormZForIntoOutofCircle: number
    intoOutofCircleSegments: number
    outofDotCircleSegments: number
    intoOutofDotThickness: number
    intoOutofCrossThickness: number
    alphaFromMagnitudeFactor: number
    backgroundColor: {number}
end

local record FieldDrawConfig
    minP: Vec2
    maxP: Vec2
    screenMin: Vec2
    screenMax: Vec2
    nPoints: {integer, integer}
    color: {number, number, number}
end

local function magnitudeToAlphaFactor(mag: number, factor: number): number
    return 1 - factor/(mag + factor)
end

local function lerpColor(bg: {number}, fg: {number}, t: number): {number}
    return {
        bg[1]*(1-t) + fg[1]*t,
        bg[2]*(1-t) + fg[2]*t,
        bg[3]*(1-t) + fg[3]*t,
        (bg[4] or 1)*(1-t) + (fg[4] or 1)*t
    }
end

local function mergeTables<T>(base: T, mods: T): T
    local merge: {string: any} = {}
    for k, v in pairs(base as {string: any}) do
        local modValue = (mods as {string: any})[k]
        if modValue == nil then
            merge[k] = v
        else
            merge[k] = modValue
        end
    end
    return merge as T
end

function MiscDrawer:drawVecNormalized(screenPos: Vec2, v: Vec3, color?: {number}, config?: VecDrawConfig)
    if config then
        config = mergeTables(self.vecConfig, config)
    else
        config = self.vecConfig
    end

    if not color then
        color = {lg.getColor()}
    end

    local colorT = magnitudeToAlphaFactor(v.mag, config.alphaFromMagnitudeFactor)
    lg.setColor(lerpColor(config.backgroundColor, color, colorT))
    v = v.normalized
    local zAlign = math.abs(v.z)
    zAlign = zAlign - config.minNormZForIntoOutofCircle
    if zAlign < 0 then
        zAlign = 0
    end
    local rootZAlign = math.sqrt(zAlign)
    v = v * config.xYMaxRadius

    local targetRadius = config.intoOutofMarkerMaxRadius * rootZAlign
    local flat = vec(v.x, v.y)
    local flatShrunk = vec.flatResize(flat, -targetRadius)
    local endPosFlat = screenPos + flatShrunk

    -- local vAngle = 180 + math.atan2(flat.y, flat.x)
    -- local openAngle = 360 * rootZAlign
    -- local arcStart = vAngle + openAngle
    -- local arcEnd = vAngle - openAngle
    local circleCenter = screenPos + flat
    circleCenter = vec.round(circleCenter)

    lg.setLineWidth(2)
    lg.line(screenPos.x, screenPos.y, endPosFlat.x, endPosFlat.y)
    lg.arc(
        "line",
        circleCenter.x,
        circleCenter.y,
        targetRadius,
        0,
        360,
        config.intoOutofCircleSegments
    )

    if v.z > 0 then
        lg.setLineWidth(0.5)
        lg.arc(
            "fill",
            circleCenter.x,
            circleCenter.y,
            config.intoOutofDotThickness,
            0,
            360,
            config.outofDotCircleSegments
        )
    else
        -- Remember, negative orientation!
        local piOver4 =  0.25 * math.pi
        local bottomRight = circleCenter + vec.frompolar(targetRadius, piOver4)
        local bottomLeft = circleCenter + vec.frompolar(targetRadius, 3*piOver4)
        local topLeft = circleCenter + vec.frompolar(targetRadius, 5*piOver4)
        local topRight = topLeft + bottomRight - bottomLeft
        lg.setLineWidth(config.intoOutofCrossThickness)
        lg.line(topRight.x, topRight.y, bottomLeft.x, bottomLeft.y)
        lg.line(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y)
    end
end

function MiscDrawer:drawVecFieldNormalized(
    f: Field,
    z: number,
    config?: FieldDrawConfig
)
    if config then
        config = mergeTables(self.fieldConfig, config)
    else
        config = self.fieldConfig
    end
    for i = 1, config.nPoints[1] do
        local tx = (i-1) / (config.nPoints[1])
        for j = 1, config.nPoints[2] do
            local ty = (j-1) / (config.nPoints[2])
            local p = vec(
                config.minP.x*(1-tx) + config.maxP.x*tx,
                config.minP.y*(1-ty) + config.maxP.y*ty,
                z
            )
            local screenPos = vec(
                config.screenMin.x*(1-tx) + config.screenMax.x*tx,
                config.screenMin.y*(1-ty) + config.screenMax.y*ty
            )
            local fv = f:value(p)
            self:drawVecNormalized(screenPos, fv, config.color)
        end
    end
end

return function(): MiscDrawer
    return setmetatable({
        vecConfig = {
            lineThickness = 2,
            intoOutofMarkerMaxRadius = 12,
            minNormZForIntoOutofCircle = 0.15,
            xYMaxRadius = 50,
            intoOutofCircleSegments = 20,
            outofDotCircleSegments = 20,
            intoOutofDotThickness = 2,
            intoOutofCrossThickness = 1,
            alphaFromMagnitudeFactor = 0.5,
            backgroundColor = {0.2, 0.2, 0.2, 1}
        },
        fieldConfig = {
            minP = vec(0, 0),
            maxP = vec(1, 1),
            nPoints = {10, 10},
            color = {1, 1, 1}
        }
    }, md_mt)
end

local vec = require "vec"
local field = require "field"

local lg = love.graphics
global record MiscDrawer
    vec: Vec

    interface Vec
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
end

local md_mt: metatable<MiscDrawer> = {__index = MiscDrawer}

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

function MiscDrawer:drawVecNormalized(screenPos: Vec2, v: Vec3, color?: {number})
    if not color then
        color = {lg.getColor()}
    end

    local colorT = magnitudeToAlphaFactor(v.mag, self.vec.alphaFromMagnitudeFactor)
    lg.setColor(lerpColor(self.vec.backgroundColor, color, colorT))
    v = v.normalized
    local zAlign = math.abs(v.z)
    zAlign = zAlign - self.vec.minNormZForIntoOutofCircle
    if zAlign < 0 then
        zAlign = 0
    end
    local rootZAlign = math.sqrt(zAlign)
    v = v * self.vec.xYMaxRadius
    v.y = -v.y

    local targetRadius = self.vec.intoOutofMarkerMaxRadius * rootZAlign
    local flat = vec(v.x, v.y)
    local flatShrunk = vec.flatResize(flat, -targetRadius)
    local endPosFlat = screenPos + flatShrunk

    local vAngle = 180 + math.atan2(flat.y, flat.x)
    local openAngle = 360 * rootZAlign
    local arcStart = vAngle + openAngle
    local arcEnd = vAngle - openAngle
    local circleCenter = screenPos + flat
    circleCenter = vec.round(circleCenter)

    lg.setLineWidth(2)
    lg.line(screenPos.x, screenPos.y, endPosFlat.x, endPosFlat.y)
    lg.arc(
        "line",
        circleCenter.x,
        circleCenter.y,
        targetRadius,
        arcStart,
        arcEnd,
        self.vec.intoOutofCircleSegments
    )

    if v.z > 0 then
        lg.setLineWidth(0.5)
        lg.arc(
            "fill",
            circleCenter.x,
            circleCenter.y,
            self.vec.intoOutofDotThickness,
            0,
            360,
            self.vec.outofDotCircleSegments
        )
    else
        -- Remember, negative orientation!
        local piOver4 =  0.25 * math.pi
        local bottomRight = circleCenter + vec.frompolar(targetRadius, piOver4)
        local bottomLeft = circleCenter + vec.frompolar(targetRadius, 3*piOver4)
        local topLeft = circleCenter + vec.frompolar(targetRadius, 5*piOver4)
        local topRight = topLeft + bottomRight - bottomLeft
        lg.setLineWidth(self.vec.intoOutofCrossThickness)
        lg.line(topRight.x, topRight.y, bottomLeft.x, bottomLeft.y)
        lg.line(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y)
    end
end

local interface DrawVecFieldArgs
    minP: Vec2
    maxP: Vec2
    screenMin: Vec2
    screenMax: Vec2
    nPoints: {integer, integer}
    color: {number, number, number}
end
function MiscDrawer:drawVecFieldNormalized(
    f: Field,
    z: number,
    args: DrawVecFieldArgs
)
    for i = 1, args.nPoints[1] do
        local tx = (i-1) / (args.nPoints[1])
        for j = 1, args.nPoints[2] do
            local ty = (j-1) / (args.nPoints[2])
            local p = vec(
                args.minP.x*(1-tx) + args.maxP.x*tx,
                args.minP.y*(1-ty) + args.maxP.y*ty,
                z
            )
            local screenPos = vec(
                args.screenMin.x*(1-tx) + args.screenMax.x*tx,
                args.screenMin.y*(1-ty) + args.screenMax.y*ty
            )
            local fieldValue = f:value(p)
            self:drawVecNormalized(screenPos, fieldValue, args.color)
        end
    end
end

return function(): MiscDrawer
    return setmetatable({
        vec = {
            lineThickness = 2,
            intoOutofMarkerMaxRadius = 12,
            minNormZForIntoOutofCircle = 0.15,
            xYMaxRadius = 50,
            intoOutofCircleSegments = 20,
            outofDotCircleSegments = 20,
            intoOutofDotThickness = 2,
            intoOutofCrossThickness = 1,
            alphaFromMagnitudeFactor = 0.5,
            backgroundColor = {0, 0, 0, 1}
        }
    }, md_mt)
end

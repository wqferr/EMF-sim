local vec = require "vec"

local lg = love.graphics
global record MiscDrawer
    vecLineThickness: number
    vecIntoOutofMarkerMaxRadius: number
    vecXYMaxRadius: number
    vecIntoOutofCircleSegments: number
    vecOutofDotCircleSegments: number
end

local md_mt: metatable<MiscDrawer> = {__index = MiscDrawer}

function MiscDrawer:drawVecNormalized(screenPos: Vec2, v: Vec3)
    v = v.normalized
    local zAlign = math.abs(v.z)
    local rootZAlign = math.sqrt(zAlign)
    v = v * self.vecXYMaxRadius
    v.y = -v.y

    local targetRadius = self.vecIntoOutofMarkerMaxRadius * rootZAlign
    local flat = vec(v.x, v.y)
    local flatShrunk = vec.flatResize(flat, -targetRadius)
    local endPosFlat = screenPos + flatShrunk

    local vAngle = 180 + math.atan2(flat.y, flat.x)
    local openAngle = 360 * rootZAlign
    local arcStart = vAngle + openAngle
    local arcEnd = vAngle - openAngle
    local circleCenter = vec.round(screenPos + flat) as Vec2

    lg.setColor(1.0, 1.0, 1.0)
    lg.setLineWidth(2)
    lg.line(screenPos.x, screenPos.y, endPosFlat.x, endPosFlat.y)
    lg.arc("line", circleCenter.x, circleCenter.y, targetRadius, arcStart, arcEnd, self.vecIntoOutofCircleSegments)

    if v.z > 0 then
        lg.setLineWidth(0.5)
        lg.arc("fill", circleCenter.x, circleCenter.y, 3, 0, 360, self.vecOutofDotCircleSegments)
    else
        -- Remember, negative orientation!
        local piOver4 = math.pi/4
        local bottomRight = circleCenter + vec.frompolar(targetRadius, piOver4)
        local bottomLeft = circleCenter + vec.frompolar(targetRadius, 3*piOver4)
        local topLeft = circleCenter + vec.frompolar(targetRadius, 5*piOver4)
        local topRight = topLeft + bottomRight - bottomLeft
        lg.setLineWidth(1)
        lg.line(topRight.x, topRight.y, bottomLeft.x, bottomLeft.y)
        lg.line(topLeft.x, topLeft.y, bottomRight.x, bottomRight.y)
    end
end

return function(): MiscDrawer
    return setmetatable({
        vecLineThickness = 2,
        vecIntoOutofMarkerMaxRadius = 12,
        vecXYMaxRadius = 50,
        vecIntoOutofCircleSegments = 20,
        vecOutofDotCircleSegments = 20,
    }, md_mt)
end

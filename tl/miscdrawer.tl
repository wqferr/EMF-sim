local vec = require "vec"

global record MiscDrawer
    vecLineThickness: number
    vecIntoOutofMarkerMaxRadius: number
    vecXYMaxRadius: number
end

function MiscDrawer:drawVecNormalized(screenPos: Vec2, v: Vec3)
    v = v.normalized
    local maxIntoOutofAreaOverPi = self.vecIntoOutofMarkerMaxRadius * self.vecIntoOutofMarkerMaxRadius
    local targetArea = maxIntoOutofAreaOverPi * v.z
    local targetRadius = math.sqrt(targetArea)
    local flat = vec(v.x, v.y)
    local flatShrunk = vec.flatResize(flat, targetRadius)
    local endPosFlat = screenPos + flatShrunk

    local circleFullness = targetRadius / self.vecIntoOutofMarkerMaxRadius
    local vAngle = math.deg(vec.angle(v, vec.posx))
    local openAngle = 360 * (1-circleFullness)
    local arcStart = vAngle - openAngle/2
    local arcEnd = vAngle + openAngle/2
    local circleCenter = screenPos + flat

    love.graphics.line(screenPos.x, screenPos.y, endPosFlat.x, endPosFlat.y)
    love.graphics.arc("line", circleCenter.x, circleCenter.y, targetRadius, arcStart, arcEnd, math.ceil(vAngle/9))
end

return function(): MiscDrawer
    return {
        vecLineThickness = 2,
        vecIntoOutofMarkerMaxRadius = 12,
        vecXYMaxRadius = 50
    }
end

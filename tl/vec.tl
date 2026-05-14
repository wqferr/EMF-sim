local interface VecModule
    posx: Vec
    negx: Vec
    posy: Vec
    negy: Vec
    posz: Vec
    negz: Vec
    posw: Vec
    negw: Vec

    zeros: function(n: integer): Vec
    ones: function(n: integer, scalar?: number): Vec
    new: function(...: number): Vec
    copy: function(v: Vec): Vec
    fromarray: function(arr: {number}, n?: integer): Vec
    fromeuler: function(mag: number, angles: {number}|number): Vec
    frompolar: function(r: number, theta: number): Vec
    fromspherical: function(r: number, polar: number, azimuth: number): Vec
    fromcylindrical: function(r: number, theta: number, z: number): Vec
    rotate: function(v: Vec, about: Vec, angle: number): Vec
    scale: function(v: Vec, scalar: number): Vec
    normalize: function(v: Vec): Vec
    angle: function(a: Vec, b: Vec): number
    dot: function(v1: Vec, v2: Vec): number
    cross: function(v1: Vec, v2: Vec): Vec
    lerp: function(v1: Vec, v2: Vec, t: number): Vec
    metamethod __call: function(self, ...: number): Vec
end

local sqrt = math.sqrt
local sin, cos = math.sin, math.cos
local acos = math.acos
local max = math.max

local M: VecModule
global interface Vec is {number}
    -- Readonly mirrors of magnitude values
    dim: integer
    mag: number
    magsqr: number
    normalized: Vec

    metamethod __add: function(a: Vec, b: Vec): Vec
    metamethod __sub: function(a: Vec, b: Vec): Vec
    metamethod __unm: function(v: Vec): Vec
    metamethod __mul: function(v: Vec, s: number): Vec
    metamethod __mul: function(s: number, v: Vec): Vec
    metamethod __mul: function(a: Vec, b: Vec): number
    metamethod __div: function(v: Vec, s: number): Vec
    metamethod __pow: function(a: Vec, b: Vec): Vec
    metamethod __len: function(v: Vec): integer
    metamethod __tostring: function(self): string
end

global interface Vec1 is Vec
    where self.dim == 1
    x: number
end

global interface Vec2 is Vec
    where self.dim == 2
    x: number
    y: number
end

global interface Vec3 is Vec
    where self.dim == 3
    x: number
    y: number
    z: number
end

global interface Vec4 is Vec
    where self.dim >= 4
    x: number
    y: number
    z: number
    w: number
end

local record InternalVec is {number}
    dim: integer
    mag: number|nil
    magsqr: number|nil
    normalized: Vec|nil
end

local private: {Vec: InternalVec} = {}
setmetatable(private, {__mode = "k"})

local vec_mt: metatable<Vec>
local intvec_mt: metatable<InternalVec>

local function fromArrWithMag(v: {number}, n: integer, mag: number): Vec
    local p: InternalVec = {}
    for i = 1, n do
        p[i] = v[i] or 0
    end
    p.mag = mag
    p.magsqr = mag*mag
    p.dim = n
    setmetatable(p, intvec_mt)

    local clone = setmetatable({} as Vec, vec_mt)
    private[clone] = p
    return clone
end

local enum CoordinateName
    "x"
    "y"
    "z"
    "w"
end

local indicesFromLetters: {CoordinateName: integer} = {
    x = 1,
    y = 2,
    z = 3,
    w = 4
}

local enum CachedProperty
    "dim"
    "mag"
    "magsqr"
    "normalized"
end

local type CacheUpdateFunction = function(InternalVec)

local function updateMagSqr(p: InternalVec)
    local m = 0.0
    for i = 1, p.dim do
        local coord = p[i]
        m = m + coord*coord
    end

    p.magsqr = m
end

local function updateMag(p: InternalVec)
    p.mag = sqrt(p.magsqr)
end

local function updateDimension(p: InternalVec)
    p.dim = #p
end

local function updateNormalized(p: InternalVec)
    p.normalized = fromArrWithMag(p, p.dim, p.mag)
    if p.mag > 0 then
        p.normalized = (p.normalized as Vec) / p.mag
    end
end

local function invalidateCache(v: Vec)
    local p = private[v]
    p.mag = nil
    p.magsqr = nil
    p.normalized = nil
end

local cacheUpdaters: {string: CacheUpdateFunction} = {
    dim = updateDimension,
    mag = updateMag,
    magsqr = updateMagSqr,
    normalized = updateNormalized,
}

intvec_mt = {
    __index = function(self: InternalVec, k: string|integer): number|integer|Vec
        if k is integer then
            if 1 <= k and k <= self.dim then
                return 0
            else
                error(
                    ("Index out of bounds: %d is not within dimension %d"):format(k, self.dim),
                    2
                )
            end
        else
            local updater = cacheUpdaters[k]
            if updater then
                updater(self)
                return rawget(
                    self as {CachedProperty: number|integer|Vec},
                    k as CachedProperty
                )
            else
                local idx = indicesFromLetters[k as CoordinateName]
                if idx then
                    return rawget(self, idx)
                else
                    return nil
                end
            end
        end
    end
}

local function ensureDimension(v: Vec, n: integer)
    local p = private[v]
    if p.dim < n then
        p.dim = n
    end
end

local function ensureSameDimension(a: Vec, b: Vec)
    local pa, pb = private[a], private[b]
    if pa.dim > pb.dim then
        pb.dim = pa.dim
    else
        pa.dim = pb.dim
    end
end

local function coerceToSameDimension(a: Vec, b: Vec): Vec, Vec
    a, b = M.copy(a), M.copy(b)
    ensureSameDimension(a, b)
    return a, b
end

vec_mt = {
    __index = function(self: Vec, k: integer|CachedProperty): number|integer|Vec
        if not private[self] then
            private[self] = setmetatable({} as InternalVec, intvec_mt)
        end
        local p = private[self] as {(integer|CachedProperty) : (number|integer|Vec)}
        return p[k]
    end,
    __newindex = function(self: Vec, k: integer|CoordinateName, v: number)
        if not private[self] then
            private[self] = setmetatable({} as InternalVec, intvec_mt)
        end
        local idx: integer
        if k is CoordinateName then
            idx = indicesFromLetters[k]
            if not idx then
                error("Invalid coordinate name: " .. k)
            end
        else
            idx = k
        end
        ensureDimension(self, idx)
        rawset(private[self], idx, v)
        invalidateCache(self)
    end,
    __add = function(a: Vec, b: Vec): Vec
        a, b = coerceToSameDimension(a, b)
        local v: {number} = {}
        for i = 1, #a do
            v[i] = a[i] + b[i]
        end
        return M.fromarray(v)
    end,
    __sub = function(a: Vec, b: Vec): Vec
        a, b = coerceToSameDimension(a, b)
        local v: {number} = {}
        for i = 1, #a do
            v[i] = a[i] - b[i]
        end
        return M.fromarray(v)
    end,
    __unm = function(v: Vec): Vec
        local u: {number} = {}
        for i = 1, #v do
            u[i] = -v[i]
        end
        return M.fromarray(u)
    end,
    __mul = function(a: Vec|number, b: Vec|number): Vec|number
        if a is Vec then
            if b is number then
                return M.scale(a, b)
            elseif b is Vec then
                return M.dot(a, b)
            end
        elseif b is Vec then
            return M.scale(b, a)
        else
            return a*b
        end
    end,
    __div = function(v: Vec, d: number): Vec
        if d == 0 then
            error("Division by 0", 2)
        end
        return M.scale(v, 1/d)
    end,
    __pow = function(a: Vec, b: Vec): Vec
        return M.cross(a, b)
    end,
    __len = function(v: Vec): integer
        return private[v].dim
    end,
    __tostring = function(v: Vec): string
        local parts: {number} = {}
        for i = 1, #v do
            table.insert(parts, v[i])
        end
        return "vec[" .. table.concat(parts, ", ") .. "]"
    end
}

M = {
    zeros = function(n: integer): Vec
        local v: {number} = {}
        for i = 1, n do
            v[i] = 0
        end
        return fromArrWithMag(v, n, 0)
    end,
    ones = function(n: integer, scalar?: number): Vec
        scalar = scalar or 1
        local mag = sqrt(n * scalar * scalar)
        local v: {number} = {}
        for i = 1, n do
            v[i] = scalar
        end
        return fromArrWithMag(v, n, mag)
    end,
    new = function(...: number): Vec
        return M.fromarray({...}, select("#", ...))
    end,
    copy = function(v: Vec): Vec
        local p = private[v]
        return fromArrWithMag(p, p.dim, p.mag)
    end,
    fromarray = function(arr: {number}, n?: integer): Vec
        if not n then
            n = #arr
        end
        local v: Vec = setmetatable({}, vec_mt)
        local p: InternalVec = {dim = n}
        for i = 1, n do
            p[i] = arr[i]
        end
        setmetatable(p, intvec_mt)
        private[v] = p
        return v
    end,
    fromeuler = function(mag: number, angles_: {number}|number): Vec
        local angles: {number} = angles_ is number and {angles_} or angles_
        if #angles > 3 then
            error("Only Euler angles (dimension 3) are supported", 2)
        end
        angles = {angles[1] or 0, angles[2] or 0, angles[3] or 0}
        local x = M.new(mag, 0, 0)
        local zup = M.new(0, 0, 1)
        local r1 = M.rotate(x, zup, angles[1])
        local newup = M.rotate(zup, x, angles[2])
        local r2 = M.rotate(r1, newup, angles[3])
        return r2
    end,
    frompolar = function(r: number, theta: number): Vec
        return M.new(r * cos(theta), r * sin(theta))
    end,
    fromspherical = function(r: number, polar: number, azimuth: number): Vec
        local sinpolar = sin(polar)
        return M.new(
            r * sinpolar * cos(azimuth),
            r * sinpolar * sin(azimuth),
            r * cos(polar)
        )
    end,
    fromcylindrical = function(r: number, theta: number, z: number): Vec
        return M.frompolar(r, theta) + M.new(0, 0, z)
    end,
    rotate = function(v: Vec, about: Vec, angle: number): Vec
        v = M.copy(v)
        about = M.copy(about)
        ensureSameDimension(v, about)
        -- https://math.stackexchange.com/questions/511370/how-to-rotate-one-vector-about-another
        local parallel = about * M.dot(v, about) / about.magsqr
        local orthogonal = v - parallel
        local cross = M.cross(about, orthogonal)
        local x1 = cos(angle) / orthogonal.mag
        local x2 = sin(angle) / cross.mag
        local rotorth = orthogonal.mag * (x1*orthogonal + x2*cross)
        return parallel + rotorth
    end,
    scale = function(v: Vec, scalar: number): Vec
        local u: {number} = {}
        for i = 1, #v do
            u[i] = scalar * v[i]
        end
        return fromArrWithMag(u, private[v].dim, scalar * v.mag)
    end,
    normalize = function(v: Vec): Vec
        return v / v.mag
    end,
    angle = function(v1: Vec, v2: Vec): number
        return acos(M.dot(v1, v2) / (v1.mag * v2.mag))
    end,
    dot = function(v1: Vec, v2: Vec): number
        v1, v2 = coerceToSameDimension(v1, v2)
        local maxlen = max(#v1, #v2)
        local d = 0.0
        for i = 1, maxlen do
            d = d + v1[i] * v2[i]
        end
        return d
    end,
    cross = function(v1: Vec, v2: Vec): Vec
        if #v1 > 3 or #v2 > 3 then
            error("Cross product must operate on 3 dimensions or less", 2)
        end

        ensureDimension(v1, 3)
        ensureDimension(v2, 3)
        return M.new(
            v1[2]*v2[3] - v1[3]*v2[2],
            v1[3]*v2[1] - v1[1]*v2[3],
            v1[1]*v2[2] - v1[2]*v2[1]
        )
    end,
    lerp = function(v1: Vec, v2: Vec, t: number): Vec
        local n = max(#v1, #v2)
        local u = M.zeros(n)
        local m = 1 - t

        for i = 1, n do
            rawset(u, i, v1[i]*m + v2[i]*t)
        end

        return u
    end
}
M.posx = M.new(1, 0, 0, 0)
M.negx = M.new(-1, 0, 0, 0)
M.posy = M.new(0, 1, 0, 0)
M.negy = M.new(0, -1, 0, 0)
M.posz = M.new(0, 0, 1, 0)
M.negz = M.new(0, 0, -1, 0)
M.posw = M.new(0, 0, 0, 1)
M.negw = M.new(0, 0, 0, -1)

local pubM: VecModule = {}
setmetatable(pubM, {
    __index = M,
    __newindex = function(_, k: string, v)
        local _, _ = k, v
        error("Cannot set values on VecModule", 2)
    end,
    __call = function(_, ...: number): Vec
        return M.new(...)
    end
} as metatable<VecModule>)

return pubM

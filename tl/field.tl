local vec = require "vec"

local interface Tensor is {Tensor}
    nidx: integer
end

local interface State
    value: Vec3
    grad: Vec3
    curl: Vec3
    div: Vec3
end

local interface Cell is Tensor
    where self.nidx == 0
    idx: Field.Index

    next: State
    current: State
end

global record Field
    type Index = {integer, integer, integer}

    values: Tensor
    dimensions: Vec3
    granularity: Vec3

    value: function(self, p: Vec3): Vec3
    curl: function(self, p: Vec3): Vec3
    numCells: function(self, axis: integer): integer
    setNext: function(self, p: Index, v: Vec3)
    commit: function(self)
end

local findCell: function(Field, Vec3): Field.Index, Vec3
local atIndex: function(Field, Field.Index): Cell
local lerpTensor: function(Tensor, Field.Index, Vec3): Vec
local newState: function(): State
local newCell: function(Field.Index): Cell
local commitCell: function(Cell)
local deriv: function(x0: number, x1: number, step: number): number

function Field:value(p: Vec3): Vec3
    local idx, cellLocalCoords = findCell(self, p)
    return lerpTensor(self.values, idx, cellLocalCoords) as Vec3
end

function Field:curl(pos: Vec3): Vec3
    local idx, _ = findCell(self, pos)
    local f = atIndex(self, idx).current
    if f.curl then
        return f.curl
    end

    local idxX: Field.Index = {idx[1]+1, idx[2], idx[3]}
    local idxY: Field.Index = {idx[1], idx[2]+1, idx[3]}
    local idxZ: Field.Index = {idx[1], idx[2], idx[3]+1}

    local fP = f.value
    local fX = atIndex(self, idxX).current.value
    local fY = atIndex(self, idxY).current.value
    local fZ = atIndex(self, idxZ).current.value
    local granularity = self.granularity

    local curl = vec.zeros(3) as Vec3

    -- del_Fz/del_y - del_Fy/del_z
    curl.x = deriv(fP.z, fY.z, granularity.y) - deriv(fP.y, fZ.y, granularity.z)

    -- del_Fx/del_z - del_Fz/del_x
    curl.y = deriv(fP.x, fZ.x, granularity.z) - deriv(fP.z, fX.z, granularity.x)

    -- del_Fy/del_x - del_Fx/del_y
    curl.z = deriv(fP.y, fX.y, granularity.x) - deriv(fP.x, fY.x, granularity.y)

    f.curl = curl
    return curl
end

function Field:stateAtIndex(idx: Field.Index): Cell
    return self.values[idx[1]][idx[2]][idx[3]] as Cell
end

function Field:numCells(axis: integer): integer
    local t = self.values
    if axis > t.nidx then
        return 0
    end

    while axis > 1 do
        t = t[1]
        axis = axis - 1
    end

    return #t
end

function Field:setNext(index: Field.Index, v: Vec3)
    local cell = self.values[index[1]][index[2]][index[3]] as Cell
    cell.next = {value = v}
end

function Field:commit()
    for _, plane in ipairs(self.values) do
        for _, row in ipairs(plane) do
            for _, cell in ipairs(row as {Cell}) do
                commitCell(cell)
            end
        end
    end
end

function findCell(field: Field, p: Vec3): Field.Index, Vec3
    local idx: Field.Index
    local cellLocalCoords: Vec3 = vec.zeros(3) as Vec3
    for i = 1, 3 do
        idx[i] = math.floor(p[i] / field.granularity[i])
        cellLocalCoords[i] = p[i] / field.granularity[i] - idx[i]
    end
    return idx, cellLocalCoords
end

function lerpTensor(t: Tensor, idx: Field.Index, coords: Vec): Vec
    if t.nidx == 0 then
        return (t as Cell).current.value
    end
    local currIdx = idx[t.nidx]
    local a = lerpTensor(t[currIdx], idx, coords)
    local b = lerpTensor(t[currIdx+1], idx, coords)
    return vec.lerp(a, b, coords[currIdx])
end

function newCell(idx: Field.Index): Cell
    return {
        idx = idx,
        current = newState(),
        next = newState()
    }
end

function newState(): State
    return {
        value = vec.zeros(3) as Vec3
    }
end

function commitCell(cell: Cell)
    cell.next, cell.current = newState(), cell.next
end

function deriv(x0: number, x1: number, step: number): number
    return (x1 - x0) / step
end

local field_mt: metatable<Field> = {
    __index = Field
}

local tensor_mt: metatable<Tensor>
tensor_mt = {
    __index = function(self: Tensor, _): Tensor
        if self.nidx == 1 then
            return newCell(nil)
        else
            return setmetatable({nidx=self.nidx-1} as Tensor, tensor_mt)
        end
    end
}

local interface FieldModule
    new: function(dimensions: Vec3, granularity: number): Field
    value: function(field: Field, p: Vec3): Vec3
    metamethod __call: function(self, dimensions: Vec3, granularity: number): Field
end

local M: FieldModule = {
    new = function(dimensions: Vec3, granularity: number): Field
        local field = setmetatable({} as Field, field_mt)
        field.dimensions = vec.copy(dimensions) as Vec3
        field.granularity = vec.ones(3, granularity) as Vec3
        field.values = {}

        -- Normalize granularity according to new dimensions.
        -- This will always reduce or keep the space between
        -- nodes, never separate them.
        local numLayers = dimensions / granularity
        for i = 1, 3 do
            numLayers[i] = math.ceil(numLayers[i])
            field.granularity[i] = dimensions[i] / numLayers[i]
        end

        for i = 1, math.floor(numLayers.x) do
            local layer: Tensor = setmetatable({nidx=2}, tensor_mt)
            field.values[i] = layer
            for j = 1, math.floor(numLayers.y) do
                local row: Tensor = setmetatable({nidx=1}, tensor_mt)
                layer[j] = row
                for k = 1, math.floor(numLayers.z) do
                    row[k] = newCell({i, j, k})
                end
            end
        end

        return field
    end,
    value = function(field: Field, p: Vec3): Vec3
        return field:value(p)
    end
}
setmetatable(M, {
    __call = function(_: FieldModule, dimensions: Vec3, granularity: number): Field
        return M.new(dimensions, granularity)
    end
})

return M

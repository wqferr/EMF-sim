local vec = require "vec"

local type FieldIndex = {integer, integer, integer}

local interface Tensor is {Tensor}
    nidx: integer
end

local interface State
    value: Vec3
    grad: Vec3
    curl: Vec3
end

local interface Cell is Tensor
    where self.nidx == 0
    idx: FieldIndex
    next: State
    current: State
end

global record Field
    values: Tensor
    dimensions: Vec3
    granularity: Vec3

    value: function(self, p: Vec3): Vec3
    curl: function(self, p: Vec3): Vec3
    numCells: function(self, axis: integer): integer
    setNext: function(self, p: Vec3, v: Vec3)
    commit: function(self)
end

local type StateAccessor = function(field: Field, idx: FieldIndex): Vec3

local findCell: function(Field, Vec3): FieldIndex, Vec3
local atIndex: function(Field, FieldIndex): Cell
local lerpTensor: function(Field, StateAccessor, FieldIndex, Vec3, integer): Vec
local newState: function(): State
local newCell: function(FieldIndex): Cell
local cellCommit: function(Cell)
local cellValue: StateAccessor
local cellGrad: StateAccessor
local cellCurl: StateAccessor
local deriv: function(x0: number, x1: number, step: number): number

function Field:value(p: Vec3): Vec3
    local idx, cellLocalCoords = findCell(self, p)
    return lerpTensor(self, cellValue, idx, cellLocalCoords, 3) as Vec3
end

function Field:grad(p: Vec3): Vec3
    local idx, cellLocalCoords = findCell(self, p)
    return lerpTensor(self, cellGrad, idx, cellLocalCoords, 3) as Vec3
end

function Field:curl(pos: Vec3): Vec3
    local idx, cellLocalCoords = findCell(self, pos)
    return lerpTensor(self, cellCurl, idx, cellLocalCoords, 3) as Vec3
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

function Field:setNext(p: Vec3, v: Vec3)
    local index, localCoords = findCell(self, p)
    for i, x in vec.ipairs(localCoords) do
        if x > 0.5 then
            index[i] = index[i] + 1
        end
    end
    local cell = self.values[index[1]][index[2]][index[3]] as Cell
    cell.next = {value = v}
end

function Field:commit()
    for i = 1, #self.values do
        local plane = self.values[i]
        for j = 1, #plane do
            local row = plane[j]
            for k = 1, #row do
                cellCommit(row[k] as Cell)
            end
        end
    end
end

function findCell(field: Field, p: Vec3): FieldIndex, Vec3
    local idx: FieldIndex = {}
    local cellLocalCoords: Vec3 = vec.zeros(3) as Vec3
    for i = 1, 3 do
        local zeroBasedIdx = math.floor(p[i] / field.granularity[i])
        cellLocalCoords[i] = (p[i] / field.granularity[i]) - zeroBasedIdx
        idx[i] = 1 + zeroBasedIdx
    end
    return idx, cellLocalCoords
end

function lerpTensor(
    field: Field,
    getter: StateAccessor,
    idx: FieldIndex,
    coords: Vec,
    remaining: integer
): Vec
    if remaining == 0 then
        return getter(field, idx)
    end
    local neighborIdx = {table.unpack(idx)}
    neighborIdx[remaining] = neighborIdx[remaining] + 1
    local a = lerpTensor(field, getter, idx, coords, remaining-1)
    local b = lerpTensor(field, getter, neighborIdx, coords, remaining-1)
    return vec.lerp(a, b, coords[remaining])
end

function newCell(idx: FieldIndex): Cell
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

function atIndex(field: Field, idx: FieldIndex): Cell
    return field.values[idx[1]][idx[2]][idx[3]] as Cell
end

function cellCommit(cell: Cell)
    cell.next, cell.current = newState(), cell.next
end

cellValue = function(field: Field, idx: FieldIndex): Vec3
    return atIndex(field, idx).current.value
end

cellGrad = function(field: Field, idx: FieldIndex): Vec3
    local f = atIndex(field, idx).current
    if f.grad then
        return f.grad
    end

    local idxX: FieldIndex = {idx[1]+1, idx[2], idx[3]}
    local idxY: FieldIndex = {idx[1], idx[2]+1, idx[3]}
    local idxZ: FieldIndex = {idx[1], idx[2], idx[3]+1}

    local fP = f.value
    local fX = atIndex(field, idxX).current.value
    local fY = atIndex(field, idxY).current.value
    local fZ = atIndex(field, idxZ).current.value
    local granularity = field.granularity

    f.grad = vec(
        deriv(fP.x, fX.x, granularity.x),
        deriv(fP.y, fY.y, granularity.y),
        deriv(fP.z, fZ.z, granularity.z)
    ) as Vec3
    return f.grad
end

cellCurl = function(field: Field, idx: FieldIndex): Vec3
    local f = atIndex(field, idx).current
    if f.curl then
        return f.curl
    end

    local idxX: FieldIndex = {idx[1]+1, idx[2], idx[3]}
    local idxY: FieldIndex = {idx[1], idx[2]+1, idx[3]}
    local idxZ: FieldIndex = {idx[1], idx[2], idx[3]+1}

    local fP = f.value
    local fX = atIndex(field, idxX).current.value
    local fY = atIndex(field, idxY).current.value
    local fZ = atIndex(field, idxZ).current.value
    local granularity = field.granularity

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
    contribute: function(field: Field, f: function(p: Vec3, value?: Vec3): Vec3)
    metamethod __call: function(self, dimensions: Vec3, granularity: number): Field
end

local M: FieldModule = {
    new = function(dimensions: Vec3, granularity: number): Field
        local field = setmetatable({} as Field, field_mt)
        field.dimensions = vec.copy(dimensions) as Vec3
        field.granularity = vec.ones(3, granularity) as Vec3
        field.values = setmetatable({nidx=3}, tensor_mt)

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
    end,
    contribute = function(field: Field, f: function(p: Vec3, value?: Vec3): Vec3)
        for i = 1, #field.values do
            local plane = field.values[i]
            for j = 1, #plane do
                local row = plane[j]
                for k = 1, #row do
                    local cell = row[k] as Cell
                    local p = vec.hadamard(
                        vec((i-1), (j-1), (k-1)),
                        field.granularity
                    )
                    cell.next.value = cell.next.value + f(p, cell.current.value)
                end
            end
        end
    end
}
setmetatable(M, {
    __call = function(_: FieldModule, dimensions: Vec3, granularity: number): Field
        return M.new(dimensions, granularity)
    end
})

return M

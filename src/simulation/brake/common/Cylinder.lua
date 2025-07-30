---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Reservoir.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/SimuTrain/src/utils/math/MathUtil.out"

local ATM_PRESSURE = 101325
local SPECIFIC_GAS_CONSTANT = 287.052874247

---@class Cylinder: Reservoir
---@field area number Effective piston area `[m²]`
---@field springStiffness number Return spring stiffness `[N/m]`
---@field springPreload number Spring preload force `[N]`
---@field friction number Friction force `[N]`
---@field additionalCapacity number Additional volume `[m³]`
---@field maxTravel number Maximum piston travel limit
---@field position number Current piston travel `[m]`
local Cylinder = {}
Cylinder.__index = Cylinder
setmetatable(Cylinder, Reservoir)

---@overload fun(area: number, springStiffness: number, springPreload: number, friction: number, maxTravel: number): Cylinder
---@overload fun(area: number, springStiffness: number, springPreload: number, friction: number, maxTravel: number, additionalCapacity: number): Cylinder
---@param area number Effective piston area `[m²]`
---@param springStiffness number Return spring stiffness `[N/m]`
---@param springPreload number Spring preload force `[N]`
---@param friction number Friction force `[N]`
---@param additionalCapacity number Additional volume e.g. connecting pipe `[m³]`
---@param pressure number Initial pressure `[Pa]`
---@return Cylinder
function Cylinder:new(area, springStiffness, springPreload, friction, maxTravel, additionalCapacity, pressure)
    ---@type Cylinder
    local instance = {
        capacity = additionalCapacity or 0.000001,
        pressure = pressure or ATM_PRESSURE,
        temperature = 273.15,

        area = area,
        springStiffness = springStiffness,
        springPreload = springPreload,
        friction = friction,
        maxTravel = maxTravel,
        additionalCapacity = additionalCapacity or 0.000001,
        position = 0
    }

    return setmetatable(instance, self)
end

function Cylinder:update()
    local force = (self.pressure - ATM_PRESSURE) * self.area - self.springStiffness * self.position - self.springPreload

    if math.abs(force) <= self.friction then return end

    local actualForce = force - self.friction * MathUtil.sign(force)
    local newPosition = self.position + actualForce / self.springStiffness
    local newCapacity = self.additionalCapacity + self.area * newPosition

    --self.pressure = self.pressure * self.capacity / newCapacity
    self.capacity = newCapacity
    self.position = MathUtil.clamp(newPosition, 0, self.maxTravel)
end

function Cylinder:changeMass(massChange)
    self.pressure = self.pressure + massChange * SPECIFIC_GAS_CONSTANT * self.temperature / self.capacity
    self:update()
end

return Cylinder
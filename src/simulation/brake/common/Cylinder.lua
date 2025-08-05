---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Reservoir.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/SimuTrain/src/utils/math/MathUtil.out"

local ATM_PRESSURE = 101325
local SPECIFIC_GAS_CONSTANT = 287.052874247

---@class Cylinder: Reservoir
---@field private area number Effective piston area `[m²]`
---@field private springStiffness number Return spring stiffness `[N/m]`
---@field private springPreload number Spring preload force `[N]`
---@field private friction number Friction force `[N]`
---@field private extensionForContact number Piston travel at which brake blocks make contact with wheel `[m]`
---@field private maxExtension number Maximum piston travel limit
---@field private additionalCapacity number Additional volume `[m³]`
---@field private position number Current piston travel `[m]`
---@field private massChange number
local Cylinder = {}
Cylinder.__index = Cylinder
setmetatable(Cylinder, Reservoir)

---@overload fun(size: number, friction: number, extensionForContact: number, maxExtension: number): Cylinder
---@overload fun(size: number, friction: number, extensionForContact: number, maxExtension: number, additionalCapacity: number): Cylinder
---@param size number Diameter of cylinder `[in]`
---@param friction number Friction force `[N]`
---@param extensionForContact number Piston extension at which brake blocks make contact with wheel `[m]`
---@param maxExtension number Maximum piston travel limit
---@param additionalCapacity number Additional volume e.g. connecting pipe `[m³]`
---@param pressure number Initial pressure `[Pa]`
---@return Cylinder
function Cylinder:new(size, friction, extensionForContact, maxExtension, additionalCapacity, pressure)
    ---@type Cylinder
    local instance = {
        capacity = additionalCapacity or 0.000001,
        pressure = pressure or ATM_PRESSURE,
        temperature = 273.15,

        area = MathUtil.getCircularAreaD(0.0254 * size),
        springStiffness = self.getSpringStiffness(size),
        springPreload = self.getSpringPreload(size),
        friction = friction,
        extensionForContact = extensionForContact,
        maxExtension = maxExtension,
        additionalCapacity = additionalCapacity or 0.000001,
        position = 0,
        massChange = 0
    }

    return setmetatable(instance, self)
end

---@param deltaTime number
function Cylinder:update(deltaTime)
    local totalStiffness = self:getMechanismStiffness()
    local force = (self.pressure - ATM_PRESSURE) * self.area - totalStiffness * self.position - self.springPreload

    self.pressure = self.pressure + self.massChange * SPECIFIC_GAS_CONSTANT * self.temperature / self.capacity
    self.massChange = 0

    if math.abs(force) <= self.friction then return end

    local actualForce = force - self.friction * MathUtil.sign(force)
    local moveSpeed = MathUtil.clamp(actualForce / totalStiffness, -0.2, 0.2)
    local newPosition = self.position + moveSpeed * deltaTime
    local newCapacity = self.additionalCapacity + self.area * newPosition

    self.capacity = newCapacity
    self.position = MathUtil.clamp(newPosition, 0, self.maxExtension)
end

function Cylinder:changeMass(massChange)
    self.massChange = self.massChange + massChange
end

---@private
function Cylinder:getMechanismStiffness()
    return self.springStiffness + MathUtil.inverseLerp(self.position, self.extensionForContact, self.extensionForContact + 0.01) * 2e6
end

---@private
---@param size number
function Cylinder.getSpringStiffness(size)
    return 45.7 * size ^ 2
end

---@private
---@param size number
function Cylinder.getSpringPreload(size)
    return 4.43643 * size + 6.53003 * size ^ 2 + 417.37363
end

return Cylinder
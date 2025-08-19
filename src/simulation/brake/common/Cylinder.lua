---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Reservoir.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/SimuTrain/src/utils/math/MathUtil.out"
---@type Easings
local Easings = require "Assets/1ab0rat0ry/SimuTrain/src/utils/Easings.out"

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
---@field private extension number Current piston travel `[m]`
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
        extension = 0,
        massChange = 0
    }

    return setmetatable(instance, self)
end

---@param deltaTime number
function Cylinder:update(deltaTime)
    local totalStiffness = self:getTotalStiffness()
    local force = self:getForce()

    self.pressure = self.pressure + self.massChange * SPECIFIC_GAS_CONSTANT * self.temperature / self.capacity
    self.massChange = 0

    if math.abs(force) <= self.friction then return end

    local actualForce = force - self.friction * MathUtil.sign(force)
    local moveSpeed = MathUtil.clamp(actualForce / totalStiffness, -0.2, 0.2)
    local newExtension = self.extension + moveSpeed * deltaTime
    local newCapacity = self.additionalCapacity + self.area * newExtension

    self.capacity = newCapacity
    self.extension = MathUtil.clamp(newExtension, 0, self.maxExtension)
end

function Cylinder:changeMass(massChange)
    self.massChange = self.massChange + massChange
end

---@return number
function Cylinder:getForce()
    return self.area * (self.pressure - ATM_PRESSURE) - self.springStiffness * self.extension - self.springPreload
end

---@private
---@return number
function Cylinder:getTotalStiffness()
    local riggingStiffness = Easings.sineIn((self.extension - self.extensionForContact) / 0.01) * 2e6

    return self.springStiffness + riggingStiffness
end

---@private
---@param size number
---@return number
function Cylinder.getSpringStiffness(size)
    return 45.7 * size ^ 2
end

---@private
---@param size number
---@return number
function Cylinder.getSpringPreload(size)
    return 4.43643 * size + 6.53003 * size ^ 2 + 417.37363
end

return Cylinder
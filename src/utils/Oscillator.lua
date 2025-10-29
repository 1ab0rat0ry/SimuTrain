---@class Oscillator
---@field private minValue number
---@field private maxValue number
---@field private reactivity number
---@field private damping number
---@field private mass number
---@field private speed number
---@field public value number
local Oscillator = {}
Oscillator.__index = Oscillator

---@param minValue number
---@param maxValue number
---@param damping number
---@param mass number
function Oscillator:new(minValue, maxValue, reactivity, damping, mass)
    ---@type Oscillator
    local instance = {
        minValue = minValue,
        maxValue = maxValue,
        reactivity = reactivity,
        damping = damping,
        mass = mass,
        speed = 0,
        value = 0
    }

    return setmetatable(instance, self)
end

---@param deltaTime number
---@param targetValue number
---@return number
function Oscillator:update(deltaTime, targetValue)
    local force = self.reactivity * (targetValue - self.value) - self.damping * self.speed

    self.speed = self.speed + (force / self.mass) * deltaTime
    self.value = self.value + self.speed * deltaTime

    if self.value < self.minValue or self.value > self.maxValue then
        self.speed = -0.5 * self.speed
        self.value = math.max(self.minValue, math.min(self.maxValue, self.value))
    end

    return self.value
end

return Oscillator
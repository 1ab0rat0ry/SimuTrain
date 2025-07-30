---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Reservoir.out"

local ATM_PRESSURE = 101325
local MIN_TIME_STEP = 0.04

---@class Pipe: Reservoir
---@field private velocity number
---@field private length number
---@field private diameter number
---@field private area number
---@field private frontCockOpen boolean
---@field private rearCockOpen boolean
---@field private previous Pipe
---@field private next Pipe
---@field private massFlow number
local Pipe = {}
Pipe.__index = Pipe
setmetatable(Pipe, Reservoir)

function Pipe:new(length, diameter)
    ---@type Pipe
    local instance = {
        capacity = 0,
        pressure = ATM_PRESSURE,
        temperature = 273.15,

        velocity = 0,
        length = length,
        diameter = diameter,
        area = math.pi * diameter ^ 2 / 4,

        frontCockOpen = false,
        rearCockOpen = false,
        previous = nil,
        next = nil,

        massFlow = 0
    }
    instance = setmetatable(instance, self)
    instance.capacity = instance.area * length

    return instance
end

---Updates state of pipe segment.
---@param deltaTime number
function Pipe:update(deltaTime)
    local steps = math.ceil(deltaTime / MIN_TIME_STEP)
    local fixedDeltaTime = deltaTime / steps

    for _ = 1, steps do
        self:calcDensity(fixedDeltaTime)
        self:calcVelocity(fixedDeltaTime)
    end

    self.massFlow = 0
end

--TODO add boundary conditions for open end
---Calculates velocity change in time using momentum equation.
--- - source: *Freight train air brake models*, equation 38
--- - available at: [https://www.tandfonline.com/doi/full/10.1080/23248378.2021.2006808](https://www.tandfonline.com/doi/full/10.1080/23248378.2021.2006808)
---@param deltaTime number
function Pipe:calcVelocity(deltaTime)
    local accel = self.velocity * self.massFlow / self:getMass()

    if self.previous and self.next then
        local dx = 0.5 * (self.previous.length + self.next.length) + self.length
        local velocityDx = (self.next.velocity - self.previous.velocity) / dx
        local pressureDx = (self.next.pressure - self.previous.pressure) / dx

        accel = accel - pressureDx / self:getDensity() - self.velocity * velocityDx
    elseif self.previous then
        local dx = 0.5 * self.previous.length + 1.5 * self.length
        local velocityDx = (-self.velocity - self.previous.velocity) / dx
        local pressureDx = (self.pressure - self.previous.pressure) / dx

        accel = accel - pressureDx / self:getDensity() - self.velocity * velocityDx
    elseif self.next then
        local dx = 1.5 * self.length + 0.5 * self.next.length
        local velocityDx = (self.next.velocity - -self.velocity) / dx
        local pressureDx = (self.next.pressure - self.pressure) / dx

        accel = accel - pressureDx / self:getDensity() - self.velocity * velocityDx
    end

    self.velocity = self.velocity + (accel + self:getResistance()) * deltaTime
end

---Calculates density change in time continuity equation.
--- - source: *Freight train air brake models*, equation 37
--- - available at: [https://www.tandfonline.com/doi/full/10.1080/23248378.2021.2006808](https://www.tandfonline.com/doi/full/10.1080/23248378.2021.2006808)
---@param deltaTime number
function Pipe:calcDensity(deltaTime)
    local densityDt = self.massFlow / self.capacity

    if self.previous and self.next then
        local dx = 0.5 * (self.previous.length + self.next.length) + self.length
        local velocityDx = (self.next.velocity - self.previous.velocity) / dx
        local densityDx = (self.next:getDensity() - self.previous:getDensity()) / dx

        densityDt = densityDt - self.velocity * densityDx - self:getDensity() * velocityDx
    elseif self.previous then
        local dx = 0.5 * self.previous.length + 1.5 * self.length
        local velocityDx = (-self.velocity - self.previous.velocity) / dx
        local densityDx = (self:getDensity() - self.previous:getDensity()) / dx

        densityDt = densityDt - self.velocity * densityDx - self:getDensity() * velocityDx
    elseif self.next then
        local dx = 1.5 * self.length + 0.5 * self.next.length
        local velocityDx = (self.next.velocity - -self.velocity) / dx
        local densityDx = (self.next:getDensity() - self:getDensity()) / dx

        densityDt = densityDt - self.velocity * densityDx - self:getDensity() * velocityDx
    end

    self:setDensity(self:getDensity() + densityDt * deltaTime)
end

---Calculates resistance due to friction.
--- - source: *Freight train air brake models*, equation 20
--- - available at: [https://www.tandfonline.com/doi/full/10.1080/23248378.2021.2006808](https://www.tandfonline.com/doi/full/10.1080/23248378.2021.2006808)
---@return number
function Pipe:getResistance()
    return -0.5 * self:getFrictionFactor() * self:getDensity() / self.diameter * self.velocity * math.abs(self.velocity)
end

---Calculates friction factor from reynolds number.
--- - source: *Freight train air brake models*, equation 22
--- - available at: [https://www.tandfonline.com/doi/full/10.1080/23248378.2021.2006808](https://www.tandfonline.com/doi/full/10.1080/23248378.2021.2006808)
---@return number
function Pipe:getFrictionFactor()
    local reynoldsNumber = self:getReynoldsNumber()

    if reynoldsNumber == 0 then
        return 0
    elseif reynoldsNumber <= 2000 then
        --laminar flow
        return 64 / reynoldsNumber
    elseif reynoldsNumber <= 4000 then
        --transition from laminar to turbulent
        return 0.00276 * reynoldsNumber ^ 0.322
    else
        --turbulent flow
        return 0.316 / reynoldsNumber ^ 0.25
    end
end

---Calculates reynolds number.
--- - source: [https://en.wikipedia.org/wiki/Reynolds_number#Definition](https://en.wikipedia.org/wiki/Reynolds_number#Definition)
---@return number
function Pipe:getReynoldsNumber()
    return self:getDensity() * math.abs(self.velocity) * self.diameter / self:getDynamicViscosity()
end

---@param previous Pipe
function Pipe:setPrevious(previous)
    self.previous = previous
    self.frontCockOpen = true

    previous.next = self
    previous.rearCockOpen = true
end

---@param next Pipe
function Pipe:setNext(next)
    self.next = next
    self.rearCockOpen = true

    next.previous = self
    next.frontCockOpen = true
end

---@param massChange number
function Pipe:changeMass(massChange)
    self.massFlow = massChange
end

return Pipe
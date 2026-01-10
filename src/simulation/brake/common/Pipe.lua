---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Reservoir.out"

local NORMAL_TEMP = 273.15
local ATM_PRESSURE = 101325

---@class Pipe: Reservoir
---@field private velocity number
---@field private length number
---@field private diameter number
---@field private area number
---@field private frontCockOpen boolean
---@field private rearCockOpen boolean
---@field private frontPipe Pipe
---@field private rearPipe Pipe
---@field private front Pipe
---@field private rear Pipe
---@field private massFlow number
local Pipe = {}
Pipe.__index = Pipe
setmetatable(Pipe, Reservoir)

function Pipe:new(length, diameter)
    ---@type Pipe
    local instance = {
        capacity = 0,
        pressure = ATM_PRESSURE,
        temperature = NORMAL_TEMP,

        velocity = 0,
        length = length,
        diameter = diameter,
        area = math.pi * diameter ^ 2 / 4,

        frontCockOpen = false,
        rearCockOpen = false,
        frontPipe = nil,
        rearPipe = nil,
        front = {},
        rear = {},

        massFlow = 0
    }
    instance = setmetatable(instance, self)
    instance.capacity = instance.area * length

    return instance
end

---Updates state of pipe segment.
---@param deltaTime number
function Pipe:update(deltaTime)
    self:updateNeighbours()
    self:integrateRK4(deltaTime)

    if math.abs(self.velocity) < 1e-9 then self.velocity = 0 end
    self.massFlow = 0
end

---Calculates time derivatives of pressure and velocity.
--- - source: *A parametric library for the simulation of a UIC pneumatic braking system*, equations 1 and 2
--- - available at: [https://flore.unifi.it/retrieve/e398c378-8947-179a-e053-3705fe0a4cff/PUGI_14.pdf](https://flore.unifi.it/retrieve/e398c378-8947-179a-e053-3705fe0a4cff/PUGI_14.pdf)
---@param pressure number
---@param density number
---@param velocity number
---@return number, number
function Pipe:calcDerivatives(pressure, density, velocity)
    local dx = 0.5 * (self.front.length + self.rear.length) + self.length
    local velocityDx = (self.rear.velocity - self.front.velocity) / dx
    local pressureDx = (self.rear.pressure - self.front.pressure) / dx

    local pressureDt = -velocity * pressureDx - pressure * velocityDx
    local velocityDt = -pressureDx / density - velocity * velocityDx + self:getResistance(density, velocity)

    return pressureDt, velocityDt
end

---Updates pressure and velocity using Euler's method
---@param deltaTime number
function Pipe:integrateEuler(deltaTime)
    local pressureDt, velocityDt = self:calcDerivatives(self.pressure, self:getDensity(), self.velocity)

    self.pressure = self.pressure + deltaTime * pressureDt
    self.velocity = self.velocity + deltaTime * velocityDt
end

---Updates pressure and velocity using Ralston's RK2 method
---@param deltaTime number
function Pipe:integrateRK2(deltaTime)
    local k1PressureDt, k1VelocityDt = self:calcDerivatives(self.pressure, self:getDensity(), self.velocity)

    local pressure2 = self.pressure + 2 / 3 * deltaTime * k1PressureDt
    local velocity2 = self.velocity + 2 / 3 * deltaTime * k1VelocityDt
    local density2 = self.getDensityFrom(pressure2, self.temperature)
    local k2PressureDt, k2VelocityDt = self:calcDerivatives(pressure2, density2, velocity2)

    self.pressure = self.pressure + deltaTime * (0.25 * k1PressureDt + 0.75 * k2PressureDt)
    self.velocity = self.velocity + deltaTime * (0.25 * k1VelocityDt + 0.75 * k2VelocityDt)
end

---Updates pressure and velocity using RK4 method
---@param deltaTime number
function Pipe:integrateRK4(deltaTime)
    local k1PressureDt, k1VelocityDt = self:calcDerivatives(self.pressure, self:getDensity(), self.velocity)

    local pressure2 = self.pressure + 0.5 * deltaTime * k1PressureDt
    local velocity2 = self.velocity + 0.5 * deltaTime * k1VelocityDt
    local density2 = self.getDensityFrom(pressure2, self.temperature)
    local k2PressureDt, k2VelocityDt = self:calcDerivatives(pressure2, density2, velocity2)

    local pressure3 = self.pressure + 0.5 * deltaTime * k2PressureDt
    local velocity3 = self.velocity + 0.5 * deltaTime * k2VelocityDt
    local density3 = self.getDensityFrom(pressure3, self.temperature)
    local k3PressureDt, k3VelocityDt = self:calcDerivatives(pressure3, density3, velocity3)

    local pressure4 = self.pressure + deltaTime * k3PressureDt
    local velocity4 = self.velocity + deltaTime * k3VelocityDt
    local density4 = self.getDensityFrom(pressure4, self.temperature)
    local k4PressureDt, k4VelocityDt = self:calcDerivatives(pressure4, density4, velocity4)

    self.pressure = self.pressure + deltaTime * (k1PressureDt + 2 * k2PressureDt + 2 * k3PressureDt + k4PressureDt) / 6
    self.velocity = self.velocity + deltaTime * (k1VelocityDt + 2 * k2VelocityDt + 2 * k3VelocityDt + k4VelocityDt) / 6
end

---Handles boundary conditions (closed end, open end) for the pipe segment.
function Pipe:updateNeighbours()
    if self.frontPipe and self.frontCockOpen then
        --- Connected to another pipe and cock is open we can use neighbour's state.
        self.front.length = self.frontPipe.length
        self.front.pressure = self.frontPipe.pressure
        self.front.velocity = self.frontPipe.velocity
    elseif self.frontCockOpen then
        --- Opened end boundary condition (no pipe connected, end of pipe is opened to atmosphere).
        --- We use virtual atmospheric segment with extrapolated pressure therefore pressure
        --- at the pipe boundary will be equal to atmospheric pressure and we get correct
        --- acceleration due to pressure gradient.
        self.front.length = self.length
        self.front.pressure = 2 * ATM_PRESSURE - self.pressure
        self.front.velocity = self.velocity
    else
        --- Closed end boundary condition. Again we use virtual segment with pressure equal
        --- to the last segment's pressure and velocity has opposite sign for correct wave reflection.
        self.front.length = self.length
        self.front.pressure = self.pressure
        self.front.velocity = -self.velocity
    end

    --- Same logic as above but for the rear end of pipe.
    if self.rearPipe and self.rearCockOpen then
        self.rear.length = self.rearPipe.length
        self.rear.pressure = self.rearPipe.pressure
        self.rear.velocity = self.rearPipe.velocity
    elseif self.rearCockOpen then
        self.rear.length = self.length
        self.rear.pressure = 2 * ATM_PRESSURE - self.pressure
        self.rear.velocity = self.velocity
    else
        self.rear.length = self.length
        self.rear.pressure = self.pressure
        self.rear.velocity = -self.velocity
    end
end

---Calculates resistance due to friction.
--- - source: *A parametric library for the simulation of a UIC pneumatic braking system*, equations 5
--- - available at: [https://flore.unifi.it/retrieve/e398c378-8947-179a-e053-3705fe0a4cff/PUGI_14.pdf](https://flore.unifi.it/retrieve/e398c378-8947-179a-e053-3705fe0a4cff/PUGI_14.pdf)
---@param density number
---@param velocity number
---@return number
function Pipe:getResistance(density, velocity)
    return -0.5 * self:getFrictionFactor(density, velocity) * density / self.diameter * velocity * math.abs(velocity)
end

---Calculates friction factor from reynolds number.
--- - source: *Freight train air brake models*, equation 22
--- - available at: [https://www.tandfonline.com/doi/full/10.1080/23248378.2021.2006808](https://www.tandfonline.com/doi/full/10.1080/23248378.2021.2006808)
---@param density number
---@param velocity number
---@return number
function Pipe:getFrictionFactor(density, velocity)
    local reynoldsNumber = self:getReynoldsNumber(density, velocity)

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
---@param density number
---@param velocity number
---@return number
function Pipe:getReynoldsNumber(density, velocity)
    return density * math.abs(velocity) * self.diameter / self:getDynamicViscosity()
end

---@param front Pipe
function Pipe:setFront(front)
    self.frontPipe = front
    self.frontCockOpen = true

    front.rearPipe = self
    front.rearCockOpen = true
end

---@param rear Pipe
function Pipe:setRear(rear)
    self.rearPipe = rear
    self.rearCockOpen = true

    rear.frontPipe = self
    rear.frontCockOpen = true
end

return Pipe
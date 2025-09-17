---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Reservoir.out"

local NORMAL_TEMP = 273.15
local ATM_PRESSURE = 101325
local ATM_DENSITY = Reservoir.getDensityFrom(ATM_PRESSURE, NORMAL_TEMP)

local MIN_TIME_STEP = 0.04


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
    local steps = math.ceil(deltaTime / MIN_TIME_STEP)
    local fixedDeltaTime = deltaTime / steps

    for _ = 1, steps do
        self:updateNeighbours()
        self:calcDensity(fixedDeltaTime)
        self:calcVelocity(fixedDeltaTime)
    end

    self.massFlow = 0
end

---Calculates velocity change in time using momentum equation.
--- - source: *Freight train air brake models*, equation 38
--- - available at: [https://www.tandfonline.com/doi/full/10.1080/23248378.2021.2006808](https://www.tandfonline.com/doi/full/10.1080/23248378.2021.2006808)
---@param deltaTime number
function Pipe:calcVelocity(deltaTime)
    local dx = 0.5 * (self.front.length + self.rear.length) + self.length
    local velocityDx = (self.rear.velocity - self.front.velocity) / dx
    local pressureDx = (self.rear.pressure - self.front.pressure) / dx
    local accel = -pressureDx / self:getDensity() - self.velocity * velocityDx

    self.velocity = self.velocity + (accel + self:getResistance()) * deltaTime
end

---Calculates density change in time continuity equation.
--- - source: *Freight train air brake models*, equation 37
--- - available at: [https://www.tandfonline.com/doi/full/10.1080/23248378.2021.2006808](https://www.tandfonline.com/doi/full/10.1080/23248378.2021.2006808)
---@param deltaTime number
function Pipe:calcDensity(deltaTime)
    local dx = 0.5 * (self.front.length + self.rear.length) + self.length
    local velocityDx = (self.rear.velocity - self.front.velocity) / dx
    local densityDx = (self.rear.density - self.front.density) / dx
    local densityDt = -self.velocity * densityDx - self:getDensity() * velocityDx

    self:setDensity(self:getDensity() + densityDt * deltaTime)
end

---Handles boundary conditions (closed end, open end) for the pipe segment.
function Pipe:updateNeighbours()
    if self.frontPipe and self.frontCockOpen then
        --- Connected to another pipe and cock is open we can use neighbour's state.
        self.front.length = self.frontPipe.length
        self.front.pressure = self.frontPipe.pressure
        self.front.velocity = self.frontPipe.velocity
        self.front.density = self.frontPipe:getDensity()
    elseif self.frontCockOpen then
        --- Opened end boundary condition (no pipe connected, end of pipe is opened to atmosphere).
        --- We use virtual atmospheric segment with extrapolated pressure therefore pressure
        --- at the pipe boundary will be equal to atmospheric pressure and we get correct
        --- acceleration due to pressure gradient. Density is set to atmospheric density
        --- for correct flow calculation.
        self.front.length = self.length
        self.front.pressure = 2 * ATM_PRESSURE - self.pressure
        self.front.velocity = self.velocity
        self.front.density = ATM_DENSITY
    else
        --- Closed end boundary condition. Again we use virtual segment with pressure equal
        --- to the last segment's pressure and velocity has opposite sign for correct wave reflection.
        self.front.length = self.length
        self.front.pressure = self.pressure
        self.front.velocity = -self.velocity
        self.front.density = self:getDensity()
    end

    --- Same logic as above but for the rear end of pipe.
    if self.rearPipe and self.rearCockOpen then
        self.rear.length = self.rearPipe.length
        self.rear.pressure = self.rearPipe.pressure
        self.rear.velocity = self.rearPipe.velocity
        self.rear.density = self.rearPipe:getDensity()
    elseif self.rearCockOpen then
        self.rear.length = self.length
        self.rear.pressure = 2 * ATM_PRESSURE - self.pressure
        self.rear.velocity = self.velocity
        self.rear.density = ATM_DENSITY
    else
        self.rear.length = self.length
        self.rear.pressure = self.pressure
        self.rear.velocity = -self.velocity
        self.rear.density = self:getDensity()
    end
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
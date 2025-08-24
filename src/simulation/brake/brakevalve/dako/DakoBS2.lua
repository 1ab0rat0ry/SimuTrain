---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Reservoir.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/SimuTrain/src/utils/math/MathUtil.out"

local REFERENCE_PRESSURE = 5
local MIN_REDUCTION_PRESSURE_DROP = 0.3
local MAX_REDUCTION_PRESSURE_DROP = 2

local CONTROL_RES_CAPACITY = 0.001

local OVERCHARGE_PRESSURE = 540000 -- [Pa]
local OVERCHGARGE_RES_CAPACITY = 0.005
local OVERCHARGE_RES_EMPTY_TIME = 180 -- [s]
local OVERCHARGE_RES_EMPTY_RATE = OVERCHARGE_PRESSURE / OVERCHARGE_RES_EMPTY_TIME -- [Pa/s]

local EMPTY_CHOKE = MathUtil.getCircularAreaD(0.00846) -- 1/3 in diameter
local FILL_CHOKE = MathUtil.getCircularAreaD(0.01693) - EMPTY_CHOKE -- 2/3 in diameter minus emptying choke size that's in the middle
local EMERGENCY_CHOKE = MathUtil.getCircularAreaD(0.0254) -- 1 in diameter

-- distributor valve parameters
local DISTRIBUTOR_PISTON_AREA = MathUtil.getCircularAreaD(0.105) - EMPTY_CHOKE -- [m^2]
local OVERCHARGE_PISTON_AREA = MathUtil.getCircularAreaD(0.0287) -- [m^2]
local SPRING_STIFFNESS = 200 -- [N/m]
local SPRING_PRELOAD = 10 -- [N]
local FRICTION = 10 -- [N]
local MOVE_COEF = 0.001 -- how much the valve moves per 1 N of force


---Selflapping driver's brake valve used mainly on older locomotives.
---@class DakoBS2
---@field private emergencyValve boolean
---@field private interruptValve number
---@field private releaseValve boolean
---@field private distributorValve number
---@field private distributorValveVel number
---
---@field private setPressure number
---@field private brakePipeChamber Reservoir
---@field private controlRes Reservoir
---@field private controlChamber Reservoir
---@field private overchargeRes Reservoir
local DakoBs2 = {}
DakoBs2.__index = DakoBs2

---@param notches table
---@return DakoBS2
function DakoBs2:new(notches)
    ---@type DakoBS2
    local instance = {
        notches = notches,
        ranges = {
            RELEASE = 0.5 * (notches.RELEASE + notches.RUNNING),
            RUNNING = 0.5 * (notches.RUNNING + notches.NEUTRAL),
            NEUTRAL = 0.5 * (notches.NEUTRAL + notches.MIN_REDUCTION),
            SERVICE = 0.5 * (notches.MAX_REDUCTION + notches.CUTOFF),
            CUTOFF = 0.5 * (notches.CUTOFF + notches.EMERGENCY),
            EMERGENCY = notches.EMERGENCY + 0.1
        },

        emergencyValve = false,
        interruptValve = 0,
        releaseValve = false,
        distributorValve = 0,
        distributorValveVel = 0,

        setPressure = 2.8,
        brakePipeChamber = Reservoir:new(0.001),
        controlRes = Reservoir:new(CONTROL_RES_CAPACITY),
        controlChamber = Reservoir:new(0.0003),
        overchargeRes = Reservoir:new(OVERCHGARGE_RES_CAPACITY)
    }

    return setmetatable(instance, self)
end

---Updates the whole brake valve.
---@param deltaTime number
---@param feedPipe Reservoir
---@param brakePipe Reservoir
function DakoBs2:update(deltaTime, feedPipe, brakePipe)
    self:updateControlMechanism(deltaTime, Call("GetControlValue", "VirtualBrake", 0), feedPipe, brakePipe)
    self:updateDistributorMechanism(deltaTime, feedPipe, brakePipe)
    self:updateOvercharge(deltaTime)
end

---Regulates pressure in control reservoir (control pressure)
---and operates release, interrupt and emergency valves based on handle position.
---@private
---@param deltaTime number
---@param position number
---@param feedPipe Reservoir
---@param brakePipe Reservoir
function DakoBs2:updateControlMechanism(deltaTime, position, feedPipe, brakePipe)
    if position <= self.ranges.RELEASE then
        --fully open release valve to allow quick filling of brake pipe
        self.emergencyValve = false
        self.interruptValve = MathUtil.towards(self.interruptValve, 1, 2 * deltaTime)
        self.releaseValve = true
    elseif position <= self.ranges.RUNNING then
        --fill brake pipe through choked connection
        self.emergencyValve = false
        self.interruptValve = MathUtil.towards(self.interruptValve, 0.12, 2 * deltaTime)
        self.releaseValve = false
        self.setPressure = REFERENCE_PRESSURE
    elseif position <= self.ranges.NEUTRAL then
        local pressureDrop = MathUtil.map(position, self.notches.MIN_REDUCTION, self.notches.MAX_REDUCTION, MIN_REDUCTION_PRESSURE_DROP, MAX_REDUCTION_PRESSURE_DROP)
        --isolate brake pipe
        self.emergencyValve = false
        self.interruptValve = MathUtil.towards(self.interruptValve, 0, 2 * deltaTime)
        self.releaseValve = false
        self.setPressure = REFERENCE_PRESSURE - pressureDrop
    elseif position <= self.ranges.SERVICE then
        --determine pressure for current brake notch
        local pressureDrop = MathUtil.map(position, self.notches.MIN_REDUCTION, self.notches.MAX_REDUCTION, MIN_REDUCTION_PRESSURE_DROP, MAX_REDUCTION_PRESSURE_DROP)

        --allow filling and emptying through choked connection
        self.emergencyValve = false
        self.interruptValve = MathUtil.towards(self.interruptValve, 0.12, 2 * deltaTime)
        self.releaseValve = false
        self.setPressure = REFERENCE_PRESSURE - pressureDrop
    elseif position <= self.ranges.CUTOFF then
        local pressureDrop = MathUtil.map(position, self.notches.MIN_REDUCTION, self.notches.MAX_REDUCTION, MIN_REDUCTION_PRESSURE_DROP, MAX_REDUCTION_PRESSURE_DROP)
        --isolate brake pipe
        self.emergencyValve = false
        self.interruptValve = MathUtil.towards(self.interruptValve, 0, 2 * deltaTime)
        self.releaseValve = false
        self.setPressure = REFERENCE_PRESSURE - pressureDrop
    elseif position <= self.ranges.EMERGENCY then
        local pressureDrop = MathUtil.map(position, self.notches.MIN_REDUCTION, self.notches.MAX_REDUCTION, MIN_REDUCTION_PRESSURE_DROP, MAX_REDUCTION_PRESSURE_DROP)
        --open emergency valve, close interrupt valve to prevent unwanted refilling
        self.emergencyValve = true
        self.interruptValve = MathUtil.towards(self.interruptValve, 0, 4 * deltaTime)
        self.releaseValve = false
        self.setPressure = REFERENCE_PRESSURE - pressureDrop
    end

    local changeRate = math.min(1, 4 * math.abs(self.setPressure - self.controlRes:getManoPressure()))

    --equalize control reservoir to set pressure
    if self.setPressure > self.controlRes:getManoPressure() + 0.001 then
        self.controlRes:equalize(feedPipe, 1e-6 * changeRate, deltaTime)
    elseif self.setPressure < self.controlRes:getManoPressure() - 0.001 then
        self.controlRes:vent(1e-6 * changeRate, deltaTime)
    end

    --quickly vent brake pipe
    if self.emergencyValve then brakePipe:vent(EMERGENCY_CHOKE, deltaTime) end
    --connect control chamber with feed pipe when handle is in RELEASE position
    --otherwise connect it with control reservoir
    if self.releaseValve then self.controlChamber:equalize(feedPipe, 4.48e-6, deltaTime)
    else self.controlChamber:equalize(self.controlRes, 4.48e-6, deltaTime)
    end
end

---Fills, empties and maintains pressure in brake pipe.
---@private
---@param deltaTime number
---@param feedPipe Reservoir
---@param brakePipe Reservoir
function DakoBs2:updateDistributorMechanism(deltaTime, feedPipe, brakePipe)
    local force = DISTRIBUTOR_PISTON_AREA * (self.controlChamber.pressure - self.brakePipeChamber.pressure) +
        OVERCHARGE_PISTON_AREA * (self.overchargeRes.pressure - 101325)

    if self.distributorValve > 0 then
        force = force - SPRING_STIFFNESS * self.distributorValve - SPRING_PRELOAD
    end

    if math.abs(force) <= FRICTION then force = 0
    else force = force - FRICTION * MathUtil.sign(force)
    end

    local maxChange = 3 * deltaTime
    local positionChange = MathUtil.clamp(MOVE_COEF * force, -maxChange, maxChange)

    self.distributorValve = MathUtil.clamp(self.distributorValve + positionChange, -1, 1)

    if math.abs(self.distributorValve) < 1e-4 and math.abs(force) < FRICTION then
        self.distributorValve = 0
    end

    if self.distributorValve > 0 then
        self.brakePipeChamber:equalize(feedPipe, FILL_CHOKE * self.distributorValve, deltaTime)
    elseif self.distributorValve < 0 then
        self.brakePipeChamber:vent(EMPTY_CHOKE * -self.distributorValve, deltaTime)
    end
    self.brakePipeChamber:equalize(brakePipe, EMERGENCY_CHOKE * self.interruptValve, deltaTime)
end

---Fills overcharge reservoir when high-pressure release is active or overcharge button is pressed.
---Slowly bleeds pressure from the reservoir to remove overcharge in brake pipe.
---@private
---@param deltaTime number
function DakoBs2:updateOvercharge(deltaTime)
    if self.overchargeRes:getManoPressure() > 0 then
        self.overchargeRes.pressure = self.overchargeRes.pressure - OVERCHARGE_RES_EMPTY_RATE * deltaTime
    end
    if self.distributorValve > 0.9 then
        self.overchargeRes:equalize(self.controlChamber, 2e-6, deltaTime)
    end
    if Call("GetControlValue", "Overcharge", 0) > 0.5 then
        self.overchargeRes:equalize(self.brakePipeChamber, 3.7e-6, deltaTime)
    end
end

return DakoBs2
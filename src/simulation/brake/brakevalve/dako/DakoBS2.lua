---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Reservoir.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/SimuTrain/src/utils/math/MathUtil.out"

local REFERENCE_PRESSURE = 5
local MIN_REDUCTION_PRESSURE_DROP = 0.3
local MAX_REDUCTION_PRESSURE_DROP = 2
local FULL_SERVICE_PRESSURE_DROP = 1.5

local CONTROL_RES_CAPACITY = 0.001
local CONTROL_RES_CHANGE_TIME = 3
local CONTROL_RES_CHANGE_RATE = FULL_SERVICE_PRESSURE_DROP / CONTROL_RES_CHANGE_TIME

local OVERCHARGE_PRESSURE = 5.4
local OVERCHGARGE_RES_CAPACITY = 0.005
local OVERCHARGE_RES_FILL_TIME = 8
local OVERCHARGE_RES_FILL_RATE = OVERCHARGE_PRESSURE / OVERCHARGE_RES_FILL_TIME
local OVERCHARGE_RES_EMPTY_RATE = 0.03

local DIST_VALVE_HYSTERESIS = 0.01

local FILL_CHOKE = 1e-4
local EMPTY_CHOKE = 1e-4
local EMERGENCY_CHOKE = 3e-4

---Regulates pressure in brake pipe based on the pressure in control chamber.
---@class DistributorValve
---@field private MAX_RESISTANCE number
---@field private resistance number
---@field public position number
---@field public controlChamber Reservoir
---@field private average MovingAverage
local DistributorValve = {
    MAX_RESISTANCE = 0.1,
    MIN_RESISTANCE = 0.001,
    resistance = 0,
    position = 0,
    controlChamber = {}
}
DistributorValve.__index = DistributorValve
DistributorValve.resistance = DistributorValve.MAX_RESISTANCE

---@return DistributorValve
function DistributorValve:new()
    ---@type DistributorValve
    local instance = {
        controlChamber = Reservoir:new(0.0003)
    }

    return setmetatable(instance, self)
end

---Updates position accordingly to pressure in control chamber and overcharge reservoir.
---@param deltaTime number
---@param brakePipe Reservoir
---@param overchargePressure number
function DistributorValve:update(deltaTime, brakePipe, overchargePressure)
    local pressureDiff = self.controlChamber:getManoPressure() - brakePipe:getManoPressure() + overchargePressure / 12.5
    local positionTarget = MathUtil.clamp(3 * pressureDiff, -1, 1)
    local positionDelta = math.abs(positionTarget - self.position)

    if positionDelta < DIST_VALVE_HYSTERESIS then
        self.resistance = math.min(self.MAX_RESISTANCE, self.resistance + self.MAX_RESISTANCE * deltaTime / 10)
    elseif positionDelta > DIST_VALVE_HYSTERESIS then
        self.resistance = math.max(self.MIN_RESISTANCE, self.resistance - positionDelta * deltaTime)
    end

    if math.abs(self.position) < DIST_VALVE_HYSTERESIS and math.abs(positionTarget) < DIST_VALVE_HYSTERESIS then
        self.position = MathUtil.towards(self.position, 0, deltaTime)
    elseif self.position < positionTarget - self.resistance then
        self.position = MathUtil.towards(self.position, positionTarget, 2 * positionDelta * deltaTime)
    elseif self.position > positionTarget + self.resistance then
        self.position = MathUtil.towards(self.position, positionTarget, 2 * positionDelta * deltaTime)
    end
end


---Selflapping driver's brake valve used mainly on older locomotives.
---@class DakoBs2
---@field private emergencyValve boolean
---@field private interruptValve number
---@field private releaseValve boolean
---@field private distributorValve DistributorValve
---@field private setPressure number
---@field private controlRes Reservoir
---@field private overchargeRes Reservoir
local DakoBs2 = {
    notches = {
        RELEASE = 0,
        RUNNING = 0,
        NEUTRAL = 0,
        MIN_REDUCTION = 0,
        MAX_REDUCTION = 0,
        CUTOFF = 0,
        EMERGENCY = 0
    },
    ranges = {
        RELEASE = 0,
        RUNNING = 0,
        NEUTRAL = 0,
        SERVICE = 0,
        CUTOFF = 0,
        EMERGENCY = 0
    },

    emergencyValve = false,
    interruptValve = 0,
    releaseValve = false,
    distributorValve = {},

    setPressure = 0,
    controlRes = {},
    overchargeRes = {},

    hasOvercharge = false
}
DakoBs2.__index = DakoBs2

---@param notches table
---@return DakoBs2
function DakoBs2:new(notches)
    ---@type DakoBs2
    local instance = {
        notches = notches,
        distributorValve = DistributorValve:new(),
        controlRes = Reservoir:new(CONTROL_RES_CAPACITY),
        overchargeRes = Reservoir:new(OVERCHGARGE_RES_CAPACITY)
    }
    instance = setmetatable(instance, self)
    instance.ranges.RELEASE = instance.notches.RELEASE + (instance.notches.RUNNING - instance.notches.RELEASE) / 2
    instance.ranges.RUNNING = instance.notches.RUNNING + (instance.notches.NEUTRAL - instance.notches.RUNNING) / 2
    instance.ranges.NEUTRAL = instance.notches.NEUTRAL + (instance.notches.MIN_REDUCTION - instance.notches.NEUTRAL) / 2
    instance.ranges.SERVICE = instance.notches.MAX_REDUCTION + (instance.notches.CUTOFF - instance.notches.MAX_REDUCTION) / 2
    instance.ranges.CUTOFF = instance.notches.CUTOFF + (instance.notches.EMERGENCY - instance.notches.CUTOFF) / 2
    instance.ranges.EMERGENCY = instance.notches.EMERGENCY

    return instance
end

---Updates the whole brake valve.
---@param deltaTime number
---@param feedPipe Reservoir
---@param brakePipe Reservoir
function DakoBs2:update(deltaTime, feedPipe, brakePipe)
    self:updateControlMechanism(deltaTime, Call("GetControlValue", "VirtualBrake", 0), feedPipe, brakePipe)
    self:updateDistributorMechanism(deltaTime, feedPipe, brakePipe)
    self:updateOvercharge(deltaTime, feedPipe, brakePipe)
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
        self.interruptValve = MathUtil.towards(self.interruptValve, 0.3, 2 * deltaTime)
        self.releaseValve = false
        self.setPressure = REFERENCE_PRESSURE
    elseif position <= self.ranges.NEUTRAL then
        --isolate brake pipe
        self.emergencyValve = false
        self.interruptValve = MathUtil.towards(self.interruptValve, 0, 2 * deltaTime)
        self.releaseValve = false
    elseif position <= self.ranges.SERVICE then
        --determine pressure for current brake notch
        local pressureDrop = MathUtil.map(position, self.notches.MIN_REDUCTION, self.notches.MAX_REDUCTION, MIN_REDUCTION_PRESSURE_DROP, MAX_REDUCTION_PRESSURE_DROP)

        --allow filling and emptying through choked connection
        self.emergencyValve = false
        self.interruptValve = MathUtil.towards(self.interruptValve, 0.3, 2 * deltaTime)
        self.releaseValve = false
        self.setPressure = REFERENCE_PRESSURE - pressureDrop
    elseif position <= self.ranges.CUTOFF then
        --isolate brake pipe
        self.emergencyValve = false
        self.interruptValve = MathUtil.towards(self.interruptValve, 0, 2 * deltaTime)
        self.releaseValve = false
    elseif position <= self.ranges.EMERGENCY then
        --open emergency valve, close interrupt valve to prevent unwanted refilling
        self.emergencyValve = true
        self.interruptValve = MathUtil.towards(self.interruptValve, 0, 4 * deltaTime)
        self.releaseValve = false
    end

    local changeRate = math.min(1, 4 * math.abs(self.setPressure - self.controlRes:getManoPressure()))

    --equalize control reservoir to set pressure
    if self.setPressure > self.controlRes:getManoPressure() then
        self.controlRes:equalize(feedPipe, 1e-6 * changeRate, deltaTime)
    elseif self.setPressure < self.controlRes:getManoPressure() then
        self.controlRes:vent(1e-6 * changeRate, deltaTime)
    end

    --quickly vent brake pipe
    if self.emergencyValve then brakePipe:vent(EMERGENCY_CHOKE, deltaTime) end
    --connect control chamber with feed pipe when handle is in RELEASE position
    --otherwise connect it with control reservoir
    if self.releaseValve then self.distributorValve.controlChamber:equalize(feedPipe, 1e-6, deltaTime)
    else self.distributorValve.controlChamber:equalize(self.controlRes, 1e-6, deltaTime)
    end
end

---Fills, empties and maintains pressure in brake pipe.
---@private
---@param deltaTime number
---@param feedPipe Reservoir
---@param brakePipe Reservoir
function DakoBs2:updateDistributorMechanism(deltaTime, feedPipe, brakePipe)
    self.distributorValve:update(deltaTime, brakePipe, self.overchargeRes:getManoPressure())

    if self.distributorValve.position > 0 then
        local fillRate = FILL_CHOKE * math.min(self.interruptValve, self.distributorValve.position)
        brakePipe:equalize(feedPipe, fillRate, deltaTime)
    elseif self.distributorValve.position < 0 then
        local emptyRate = EMPTY_CHOKE * math.max(self.interruptValve, self.distributorValve.position)
        brakePipe:vent(emptyRate, deltaTime)
    end
end

---Fills overcharge reservoir when high-pressure release is active or overcharge button is pressed.
---Slowly bleeds pressure from the reservoir to remove overcharge in brake pipe.
---@private
---@param deltaTime number
---@param feedPipe Reservoir
---@param brakePipe Reservoir
function DakoBs2:updateOvercharge(deltaTime, feedPipe, brakePipe)
    if self.overchargeRes:getManoPressure() > 0 then self.overchargeRes:vent(0.5e-6, deltaTime) end
    if self.distributorValve.controlChamber:getManoPressure() > 5.1 and self.distributorValve.position > 0.3 then
        self.overchargeRes:equalize(feedPipe, 1e-6, deltaTime)
    elseif self.hasOvercharge and Call("GetControlValue", "Overcharge", 0) > 0.5 then
        self.overchargeRes:equalize(brakePipe, 1e-6, deltaTime)
    end
end

return DakoBs2
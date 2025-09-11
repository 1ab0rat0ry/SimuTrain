---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Reservoir.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/SimuTrain/src/utils/math/MathUtil.out"
---@type Curve
local Curve = require "Assets/1ab0rat0ry/SimuTrain/src/utils/math/Curve.out"

local REFERENCE_PRESSURE = 5 -- [bar]
local MIN_REDUCTION_PRESSURE_DROP = 0.3 -- [bar]
local MAX_REDUCTION_PRESSURE_DROP = 2 -- [bar]
local EMERGENCY_PRESSURE_DROP = 2.2 -- [bar]
local OVERCHARGE_PRESSURE = 540000

local CONTROL_RES_CAPACITY = 0.001

local OVERCHARGE_RES_CAPACITY = 0.005
local OVERCHARGE_RES_EMPTY_TIME = 180 -- [s]
local OVERCHARGE_RES_EMPTY_RATE = OVERCHARGE_PRESSURE / OVERCHARGE_RES_EMPTY_TIME -- [Pa/s]

-- Chokes calibrated using measured dimensions from the book:
-- Ing. Ján Hrušovský – Brzdiče hnacích vozidiel ČSD, appendix, figure 66.
local EMPTY_CHOKE = MathUtil.getCircularAreaD(0.01)
-- Subtract the emptying choke area because it sits in the center of the filling choke.
local FILL_CHOKE = MathUtil.getCircularAreaD(0.022) - EMPTY_CHOKE
local EMERGENCY_CHOKE = MathUtil.getCircularAreaD(0.026) - MathUtil.getCircularAreaD(0.008)

-- distributor mechanism parameters
-- Subtract emptying choke area because it passes through.
local DISTRIBUTOR_PISTON_AREA = MathUtil.getCircularAreaD(0.106) - EMPTY_CHOKE
local OVERCHARGE_PISTON_AREA = MathUtil.getCircularAreaD(0.029)
local SPRING_STIFFNESS = 300 -- [N/m]
local SPRING_PRELOAD = 9 -- [N]
local FRICTION = 10 -- [N]
local MOVE_COEF = 0.001 -- how much the valve moves per 1 N of force


--- Self lapping driver's brake valve used mainly on older locomotives.
--- @class DakoBS2
--- @field private notches table<string, number>
--- @field private thresholds table<string, number>
--- @field private interruptValveCurve Curve
--- @field private setPressureCurve Curve
--- @field private emergencyValve boolean
--- @field private interruptValve number
--- @field private distributorValve number
---
--- @field private brakePipeChamber Reservoir
--- @field private controlRes Reservoir
--- @field private controlChamber Reservoir
--- @field private overchargeRes Reservoir
local DakoBS2 = {}
DakoBS2.__index = DakoBS2

--- @param notches table<string, number>
--- @return DakoBS2
function DakoBS2:new(notches)
    ---@type DakoBS2
    local instance = {
        notches = notches,
        thresholds = {
            RUNNING = 0.5 * (notches.RELEASE + notches.RUNNING),
            NEUTRAL = 0.5 * (notches.RUNNING + notches.NEUTRAL),
            MIN_REDUCTION = 0.5 * (notches.NEUTRAL + notches.MIN_REDUCTION),
            CUTOFF = 0.5 * (notches.MAX_REDUCTION + notches.CUTOFF),
            EMERGENCY = 0.5 * (notches.CUTOFF + notches.EMERGENCY)
        },
        setPressureCurve = Curve:new({
            {notches.NEUTRAL, REFERENCE_PRESSURE},
            {notches.MIN_REDUCTION, REFERENCE_PRESSURE - MIN_REDUCTION_PRESSURE_DROP},
            {notches.MAX_REDUCTION, REFERENCE_PRESSURE - MAX_REDUCTION_PRESSURE_DROP},
            {notches.EMERGENCY, REFERENCE_PRESSURE - EMERGENCY_PRESSURE_DROP}
        }),
        interruptValve = 0,
        emergencyValve = false,
        distributorValve = 0,

        brakePipeChamber = Reservoir:new(0.001),
        controlRes = Reservoir:new(CONTROL_RES_CAPACITY),
        controlChamber = Reservoir:new(0.0003),
        overchargeRes = Reservoir:new(OVERCHARGE_RES_CAPACITY)
    }

    return setmetatable(instance, self)
end

--- Updates the whole brake valve.
--- @param deltaTime number
--- @param feedPipe Reservoir
--- @param brakePipe Reservoir
function DakoBS2:update(deltaTime, feedPipe, brakePipe)
    self:updateControlMechanism(deltaTime, Call("GetControlValue", "VirtualBrake", 0), feedPipe, brakePipe)
    self:updateDistributorMechanism(deltaTime, feedPipe, brakePipe)
    self:updateOvercharge(deltaTime)
end

--- Regulates pressure in control reservoir (control pressure)
--- and operates release, interrupt and emergency valves based on handle position.
--- @private
--- @param deltaTime number
--- @param position number
--- @param feedPipe Reservoir
--- @param brakePipe Reservoir
function DakoBS2:updateControlMechanism(deltaTime, position, feedPipe, brakePipe)
    --- Emergency valve connects brake pipe to atmosphere through large cross-section area
    --- when handle is in emergency position (variable is `true`).
    self.emergencyValve = position > self.thresholds.EMERGENCY
    --- Interrupt valve controls the connection between brake pipe and distributor mechanism.
    --- It is closed in emergency, cutoff and neutral handle positions.
    --- In service range and running position it is partially open.
    --- In release position it is fully open, to quickly fill brake pipe with full pressure of main reservoir.
    self.interruptValve = self:getInterruptValve(position)
    --- When handle is in release position (variable is `true`),
    --- it connects control chamber to main reservoir,
    --- to allow filling of brake pipe with full pressure of main reservoir.
    --- Otherwise control chamber is connected to control reservoir.
    local releaseValve = position < self.thresholds.RUNNING
    --- Control reservoir target pressure depending on handle position.
    --- In release and running positions 5 bar, in minimum reduction 4.7 bar,
    --- in maximum reduction 3 bar and in emergency 2.8 bar.
    local setPressure = self.setPressureCurve:getValue(position)
    local controlValve = math.min(1, 4 * math.abs(setPressure - self.controlRes:getManoPressure()))

    if setPressure > self.controlRes:getManoPressure() + 0.001 then
        self.controlRes:equalize(feedPipe, 5.628e-7 * controlValve, deltaTime)
    elseif setPressure < self.controlRes:getManoPressure() - 0.001 then
        self.controlRes:vent(5.628e-7 * controlValve, deltaTime)
    end

    if self.emergencyValve then brakePipe:vent(EMERGENCY_CHOKE, deltaTime) end
    if releaseValve then self.controlChamber:equalize(feedPipe, 1.963e-5, deltaTime)
    else self.controlChamber:equalize(self.controlRes, 1.257e-5, deltaTime)
    end
end

--- Fills, empties and maintains pressure in brake pipe.
--- @private
--- @param deltaTime number
--- @param feedPipe Reservoir
--- @param brakePipe Reservoir
function DakoBS2:updateDistributorMechanism(deltaTime, feedPipe, brakePipe)
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

--- @private
--- @param deltaTime number
function DakoBS2:updateOvercharge(deltaTime)
    --- Simple simulation of linear venting mechanism. It slowly bleeds pressure from overcharge reservoir
    --- to remove overcharge in the brake pipe.
    if self.overchargeRes:getManoPressure() > 0 then
        self.overchargeRes.pressure = self.overchargeRes.pressure - OVERCHARGE_RES_EMPTY_RATE * deltaTime
    end
    -- Fill overcharge reservoir when high-pressure release is active.
    if self.distributorValve > 0.99 then
        self.overchargeRes:equalize(self.controlChamber, 2.057e-6, deltaTime)
    end
    -- Fill overcharge reservoir if overcharge button is pressed.
    if Call("GetControlValue", "Overcharge", 0) > 0.5 then
        self.overchargeRes:equalize(self.brakePipeChamber, 4.212e-6, deltaTime)
    end
end

--- @private
--- @param position number Handle position.
--- @return number Percentage of opening.
function DakoBS2:getInterruptValve(position)
    if position < self.thresholds.RUNNING then return 1
    elseif position < self.thresholds.NEUTRAL then return 0.15
    elseif position < self.thresholds.MIN_REDUCTION then return 0
    elseif position < self.thresholds.CUTOFF then return 0.15
    end

    return 0
end

return DakoBS2
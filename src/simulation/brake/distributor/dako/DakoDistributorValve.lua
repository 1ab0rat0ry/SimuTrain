---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/SimuTrain/src/utils/math/MathUtil.out"
---@type MovingAverage
local MovingAverage = require "Assets/1ab0rat0ry/SimuTrain/src/utils/math/MovingAverage.out"

local MAX_RESISTANCE = 0.5
local MIN_RESISTANCE = 0.005
local HYSTERESIS = 0.01
local CYLINDER_MAX_PRESSURE = 3.8

---@class DakoDistributorValve
---@field private MAX_HYSTERESIS number
---@field private resistance number
---@field public position number
---@field private pressureCoef number
---@field private average MovingAverage
local DakoDistributorValve = {
    resistance = MAX_RESISTANCE,
    position = 0,
    pressureCoef = 0,
    average = {}
}
DakoDistributorValve.__index = DakoDistributorValve

---@param pressureCoef number
function DakoDistributorValve:new(pressureCoef)
    ---@type DakoDistributorValve
    local instance = {
        pressureCoef = pressureCoef,
        average = MovingAverage:new(3)
    }
    instance = setmetatable(instance, self)

    return instance
end

---Calculates target cylinder pressure and updates position accordingly.
---@param deltaTime number
---@param brakePipe Reservoir
---@param distributorRes Reservoir
---@param cylinder Reservoir
function DakoDistributorValve:update(deltaTime, brakePipe, distributorRes, cylinder)
    local pressureCalculated = (distributorRes:getManoPressure() - brakePipe:getManoPressure()) * self.pressureCoef
    local pressureDiff = pressureCalculated - cylinder:getManoPressure()
    local pressureLimit = 3 * (CYLINDER_MAX_PRESSURE - cylinder:getManoPressure())
    local positionTarget = MathUtil.clamp(3 * pressureDiff, -1, math.min(1, pressureLimit))
    local positionDelta = math.abs(positionTarget - self.position)

    if math.abs(self.position) < HYSTERESIS and positionDelta < HYSTERESIS then
        self.resistance = math.min(MAX_RESISTANCE, self.resistance + MAX_RESISTANCE * deltaTime / 10)
    elseif positionDelta > HYSTERESIS then
        self.resistance = math.max(MIN_RESISTANCE, self.resistance - positionDelta * deltaTime)
    end

    if math.abs(self.position) < HYSTERESIS and math.abs(positionTarget) < HYSTERESIS then
        self.position = MathUtil.towards(self.position, 0, deltaTime)
    elseif self.position < positionTarget - self.resistance then
        self.average:sample(positionTarget)
        self.position = MathUtil.towards(self.position, positionTarget, 2 * positionDelta * deltaTime)
    elseif self.position > positionTarget + self.resistance then
        self.average:sample(positionTarget)
        self.position = MathUtil.towards(self.position, positionTarget, 2 * positionDelta * deltaTime)
    end
end

return DakoDistributorValve
---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Reservoir.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/SimuTrain/src/utils/math/MathUtil.out"
---@type DakoDistributorValve
local DakoDistributorValve = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/distributor/dako/DakoDistributorValve.out"

local CYLINDER_PRESSURE_COEF = 2.533
local CYLINDER_INSHOT_PRESSURE = 0.69

local ACCEL_CHAMBER_CAPACITY = 0.00046

local VENT_VALVE_CLOSE_THRESHOLD = 0.4
local VENT_VALVE_OPEN_THRESHOLD = 0.2

local ACCELERATION_CHOKE = 1e-5
local VENTILATION_CHOKE = 3e-6
local AUX_RES_CHOKE = 4.4e-6
local DISTRIBUTOR_RES_CHOKE = 3.96e-7
local AUX_RES_REFILL_CHOKE = 1.5e-5
local INSHOT_CHOKE = 1e-4
local CYLINDER_FILL_CHOKE = MathUtil.getCircularAreaD(0.006)
local CYLINDER_EMPTY_CHOKE = MathUtil.getCircularAreaD(0.006)

---@class DakoBv1: Distributor
---@field public turnOffValve boolean
---@field private acceleratorValve number
---@field private ventilationValve number
---@field private distributorValve DakoDistributorValve
---@field private inshotValve number
---
---@field private brakePipeChamber Reservoir
---@field private accelerationChamber Reservoir
---@field private distributorRes Reservoir
---@field private auxiliaryRes Reservoir
---@field private outputRes Reservoir
local DakoBv1 = {}
DakoBv1.__index = DakoBv1

---@param brakePipe Pipe
---@param distributorRes Reservoir
---@param auxiliaryRes Reservoir
---@param outputRes Reservoir
---@return DakoBv1
function DakoBv1:new(brakePipe, distributorRes, auxiliaryRes, outputRes)
    ---@type DakoBv1
    local instance = {
        turnOffValve = true,
        acceleratorValve = 0,
        ventilationValve = 0,
        distributorValve = DakoDistributorValve:new(CYLINDER_PRESSURE_COEF),
        inshotValve = 1,

        brakePipeChamber = brakePipe,
        accelerationChamber = Reservoir:new(ACCEL_CHAMBER_CAPACITY),
        distributorRes = distributorRes,
        auxiliaryRes = auxiliaryRes,
        outputRes = outputRes
    }
    instance = setmetatable(instance, self)

    return instance
end

---Updates the whole distributor.
---@param deltaTime number
function DakoBv1:update(deltaTime)
    --local brakePipeChamber = self.turnOffValve and self.brakePipeChamber or Reservoir.atmosphere

    self:updateAcceleratorMechanism(deltaTime)
    self:updateEqualizingMechanism(deltaTime)
    self:updateConnectingMechanism(deltaTime)
    self:updateDistributorMechanism(deltaTime)
end

---Accelerates propagation of the lower pressure wave by taking air from brake pipe into acceleration chamber.
---@private
---@param deltaTime number
function DakoBv1:updateAcceleratorMechanism(deltaTime)
    self.acceleratorValve = MathUtil.clamp(0.0005 * (self.auxiliaryRes.pressure - self.brakePipeChamber.pressure) / 10 - 0.1, 0, 1)

    if self.outputRes:getManoPressure() > VENT_VALVE_CLOSE_THRESHOLD then
        self.ventilationValve = MathUtil.towards(self.ventilationValve, 0, 2 * deltaTime)
    elseif self.outputRes:getManoPressure() < VENT_VALVE_OPEN_THRESHOLD then
        self.ventilationValve = MathUtil.towards(self.ventilationValve, 1, 2 * deltaTime)
    end
    self.brakePipeChamber:equalize(self.accelerationChamber, ACCELERATION_CHOKE * self.acceleratorValve, deltaTime)
    self.accelerationChamber:vent(VENTILATION_CHOKE * self.ventilationValve, deltaTime)
end

---Controls filling of distributor and auxiliary reservoir.
---@private
---@param deltaTime number
function DakoBv1:updateEqualizingMechanism(deltaTime)
    if self.outputRes:getManoPressure() < 0.3 then
        self.distributorRes:equalize(self.brakePipeChamber, DISTRIBUTOR_RES_CHOKE, deltaTime)
        self.auxiliaryRes:equalize(self.brakePipeChamber, AUX_RES_CHOKE, deltaTime)
    end
end

---Refills auxiliary reservoir.
---@private
---@param deltaTime number
function DakoBv1:updateConnectingMechanism(deltaTime)
    local shutterValve = MathUtil.clamp(10 * (self.brakePipeChamber:getManoPressure() - self.auxiliaryRes:getManoPressure() - 0.1), 0, 1)
    local refillValve = MathUtil.clamp(5 * (self.distributorRes:getManoPressure() - self.auxiliaryRes:getManoPressure() - 0.1), 0, 1)

    if self.brakePipeChamber:getManoPressure() - self.auxiliaryRes:getManoPressure() > 1 then
        shutterValve = 0.2
    end
    self.auxiliaryRes:equalize(self.brakePipeChamber, AUX_RES_REFILL_CHOKE * math.min(shutterValve, refillValve), deltaTime)
end

---Regulates pressure in brake cylinder.
---@private
---@param deltaTime number
function DakoBv1:updateDistributorMechanism(deltaTime)
    self.distributorValve:update(deltaTime, self.brakePipeChamber, self.distributorRes, self.outputRes)

    local inshotValve = MathUtil.inverseLerp(self.outputRes:getManoPressure(), CYLINDER_INSHOT_PRESSURE, CYLINDER_INSHOT_PRESSURE - 0.1)

    if self.distributorValve.position > 0 then
        self.outputRes:equalize(self.auxiliaryRes, self.distributorValve.position * (CYLINDER_FILL_CHOKE + INSHOT_CHOKE * inshotValve), deltaTime)
    elseif self.distributorValve.position < 0 then
        self.outputRes:vent(CYLINDER_EMPTY_CHOKE * math.abs(self.distributorValve.position), deltaTime)
    end
end

return DakoBv1
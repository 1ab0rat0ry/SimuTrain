---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Reservoir.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/SimuTrain/src/utils/math/MathUtil.out"

local CYLINDER_PRESSURE_COEF = 2.667
local CYLINDER_INSHOT_PRESSURE = 0.69
local CYLINDER_MAX_PRESSURE = 3.8

local ACCEL_CHAMBER_CAPACITY = 0.00046

local VENT_VALVE_CLOSE_THRESHOLD = 0.4
local VENT_VALVE_OPEN_THRESHOLD = 0.2

local ACCELERATION_CHOKE = 1e-5
local VENTILATION_CHOKE = 3e-6
local AUX_RES_CHOKE = MathUtil.getCircularAreaD(0.0023)
local DISTRIBUTOR_RES_CHOKE = MathUtil.getCircularAreaD(0.00059)
local AUX_RES_REFILL_CHOKE_1 = MathUtil.getCircularAreaD(0.0022)
local AUX_RES_REFILL_CHOKE_2 = MathUtil.getCircularAreaD(0.0018)
local INSHOT_CHOKE = 0.5e-5
local CYLINDER_FILL_CHOKE = MathUtil.getCircularAreaD(0.006)
local CYLINDER_EMPTY_CHOKE = MathUtil.getCircularAreaD(0.0032)

local DISTRIBUTOR_PISTON_AREA = MathUtil.getCircularAreaD(0.085)

---@class DakoBV1: Distributor
---@field public turnOffValve boolean
---@field private acceleratorValve number
---@field private ventilationValve number
---@field private distributorValve number
---@field private inshotValve number
---
---@field private brakePipeChamber Reservoir
---@field private accelerationChamber Reservoir
---@field private distributorRes Reservoir
---@field private auxiliaryRes Reservoir
---@field private outputRes Cylinder
local DakoBV1 = {}
DakoBV1.__index = DakoBV1

---@param brakePipe Pipe
---@param distributorRes Reservoir
---@param auxiliaryRes Reservoir
---@param outputRes Reservoir
---@return DakoBV1
function DakoBV1:new(brakePipe, distributorRes, auxiliaryRes, outputRes)
    ---@type DakoBV1
    local instance = {
        turnOffValve = true,
        acceleratorValve = 0,
        ventilationValve = 0,
        distributorValve = 0,
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
function DakoBV1:update(deltaTime)
    --local brakePipeChamber = self.turnOffValve and self.brakePipeChamber or Reservoir.atmosphere

    self:updateAcceleratorMechanism(deltaTime)
    self:updateEqualizingMechanism(deltaTime)
    self:updateConnectingMechanism(deltaTime)
    self:updateDistributorMechanism(deltaTime)
end

---Accelerates propagation of the lower pressure wave by taking air from brake pipe into acceleration chamber.
---@private
---@param deltaTime number
function DakoBV1:updateAcceleratorMechanism(deltaTime)
    self.acceleratorValve = MathUtil.inverseLerp(1e-5 * (self.auxiliaryRes.pressure - self.brakePipeChamber.pressure), 0.1, 0.15)

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
function DakoBV1:updateEqualizingMechanism(deltaTime)
    if self.outputRes:getManoPressure() < 0.2 then
        self.distributorRes:equalize(self.brakePipeChamber, DISTRIBUTOR_RES_CHOKE, deltaTime)
        self.auxiliaryRes:equalize(self.brakePipeChamber, AUX_RES_CHOKE, deltaTime)
    end
end

---Refills auxiliary reservoir.
---@private
---@param deltaTime number
function DakoBV1:updateConnectingMechanism(deltaTime)
    if self.distributorRes:getManoPressure() < self.auxiliaryRes:getManoPressure() + 0.1 then return end

    local shutterValve = MathUtil.inverseLerp(1e-5 * (self.brakePipeChamber.pressure - self.auxiliaryRes.pressure), 0.01, 0.05)
    local refillChoke = AUX_RES_REFILL_CHOKE_1 + AUX_RES_REFILL_CHOKE_2

    if self.brakePipeChamber:getManoPressure() - self.auxiliaryRes:getManoPressure() > 1 then
        refillChoke = AUX_RES_REFILL_CHOKE_2
    end
    self.auxiliaryRes:equalize(self.brakePipeChamber, refillChoke * shutterValve, deltaTime)
end

---Regulates pressure in brake cylinder.
---@private
---@param deltaTime number
function DakoBV1:updateDistributorMechanism(deltaTime)
    local inshotValve = MathUtil.inverseLerp(
        self.outputRes:getManoPressure(),
        CYLINDER_INSHOT_PRESSURE,
        CYLINDER_INSHOT_PRESSURE - 0.1
    )

    self:updateDistributorValve(deltaTime)

    if self.distributorValve > 0 then
        self.outputRes:equalize(self.auxiliaryRes, inshotValve * self.distributorValve * INSHOT_CHOKE, deltaTime)
        self.outputRes:equalize(self.auxiliaryRes, self.distributorValve * CYLINDER_FILL_CHOKE, deltaTime)
    elseif self.distributorValve < 0 then
        self.outputRes:vent(-self.distributorValve * CYLINDER_EMPTY_CHOKE, deltaTime)
    end
    self.outputRes:update(deltaTime)
end

---Updates position of distributor valve.
---@param deltaTime number
function DakoBV1:updateDistributorValve(deltaTime)
    local outputPressureBar = self.outputRes:getManoPressure()
    local outputPressureTarget = CYLINDER_PRESSURE_COEF * (self.distributorRes:getManoPressure() - self.brakePipeChamber:getManoPressure()) - 0.2
    local distributorValveTarget = MathUtil.clamp(4 * (outputPressureTarget - outputPressureBar), -1, 1)
    local pressureLimit = MathUtil.inverseLerp(
        outputPressureBar,
        CYLINDER_MAX_PRESSURE,
        CYLINDER_MAX_PRESSURE - 0.2)

    if outputPressureTarget < CYLINDER_INSHOT_PRESSURE and distributorValveTarget > 0 then
        distributorValveTarget = MathUtil.clamp(4 * (CYLINDER_INSHOT_PRESSURE - outputPressureBar), -1, 1)
    end
    self.distributorValve = self.distributorValve + (distributorValveTarget - self.distributorValve) * deltaTime
    self.distributorValve = math.min(pressureLimit, self.distributorValve)

    if math.abs(self.distributorValve) < 1e-4 then
        self.distributorValve = 0
    end
end

return DakoBV1
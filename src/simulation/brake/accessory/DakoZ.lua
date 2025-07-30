---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Reservoir.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/SimuTrain/src/utils/math/MathUtil.out"

local INTERRUPT_VALVE_CLOSE_THRESHOLD = -0.1
local INTERRUPT_VALVE_OPEN_THRESHOLD = 0

local VENTILATION_VALVE_CLOSE_THRESHOLD = 0.075
local VENTILATION_VALVE_OPEN_THRESHOLD = 0.08

local SENSITIVITY_CHOKE = 4e-6
local ACCELERATION_CHOKE = 1e-3
local VENTILATION_CHOKE = 1e-5

---@class DakoZ
---@field public turnOffValve boolean
---@field private controlChamber Reservoir
---@field private expansionRes Reservoir
local DakoZ = {
    turnOffValve = true,
    controlChamber = {},
    expansionRes = {}
}
DakoZ.__index = DakoZ

---@return DakoZ
function DakoZ:new()
    ---@type DakoZ
    local instance = {
        controlChamber = Reservoir:new(0.0003),
        expansionRes = Reservoir:new(0.008)
    }
    instance = setmetatable(instance, self)
    instance.controlChamber.pressure = 601325

    return instance
end

---@param deltaTime number
---@param brakePipe Reservoir
---@param auxiliaryRes Reservoir
function DakoZ:update(deltaTime, brakePipe, distributor)
    local interruptValve = MathUtil.inverseLerp(
        distributor.auxiliaryRes:getManoPressure() - brakePipe:getManoPressure(),
        INTERRUPT_VALVE_CLOSE_THRESHOLD,
        INTERRUPT_VALVE_OPEN_THRESHOLD
    )
    local accelerationValve = MathUtil.inverseLerp(
        self.controlChamber:getManoPressure() - brakePipe:getManoPressure(),
        VENTILATION_VALVE_CLOSE_THRESHOLD,
        VENTILATION_VALVE_OPEN_THRESHOLD
    )

    self.controlChamber:equalize(brakePipe, deltaTime, SENSITIVITY_CHOKE * interruptValve)
    brakePipe:equalize(self.expansionRes, deltaTime, ACCELERATION_CHOKE * accelerationValve)
    self.expansionRes:vent(deltaTime, VENTILATION_CHOKE)
end

return DakoZ
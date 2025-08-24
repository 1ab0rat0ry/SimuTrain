---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Reservoir.out"
---@type Cylinder
local Cylinder = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Cylinder.out"
---@type Vehicle
local Vehicle = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/rollingstock/Vehicle.out"
---@type DakoBv1
local DakoBv1 = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/distributor/dako/DakoBV1.out"
---@type DakoBS2
local DakoBs2 = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/brakevalve/dako/DakoBS2.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/SimuTrain/src/utils/math/MathUtil.out"

local LENGTH = 24.5
local MAIN_RES_CAPACITY = 0.4
local DISTRIBUTOR_RES_CAPACITY = 0.009
local AUXILIARY_RES_CAPACITY = 0.1
local BS2_NOTCHES = {
    RELEASE = 0,
    RUNNING = 0.1,
    NEUTRAL = 0.18,
    MIN_REDUCTION = 0.28,
    MAX_REDUCTION = 0.78,
    CUTOFF = 0.86,
    EMERGENCY = 1
}

---@class Cd460: Vehicle
local Cd460 = {}

---@return Cd460
function Cd460:new()
    ---@type Cd460
    local instance = Vehicle:new(LENGTH)

    instance.distributorRes = Reservoir:new(DISTRIBUTOR_RES_CAPACITY)
    instance.auxiliaryRes = Reservoir:new(AUXILIARY_RES_CAPACITY)
    instance.cylinder = Cylinder:new(16, 700, 0.15, 0.2, 0.001)
    instance:addFeedPipe(MAIN_RES_CAPACITY)
    instance:addDistributor(DakoBv1:new(instance.brakePipe, instance.distributorRes, instance.auxiliaryRes, instance.cylinder))
    instance:addBrakeValve(DakoBs2:new(BS2_NOTCHES))

    return instance
end

return Cd460
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

local LENGTH = 17.7
local MAIN_RES_CAPACITY = 1.33
local DISTRIBUTOR_RES_CAPACITY = 0.009
local AUXILIARY_RES_CAPACITY = 0.1
local BS2_NOTCHES = {
    RELEASE = 0,
    RUNNING = 0.15,
    NEUTRAL = 0.225,
    MIN_REDUCTION = 0.35,
    MAX_REDUCTION = 0.71,
    CUTOFF = 0.81,
    EMERGENCY = 1
}

---@class ZSSKC183: Vehicle
local ZSSKC183 = {}

---@return ZSSKC183
function ZSSKC183:new()
    ---@type ZSSKC183
    local instance = Vehicle:new(LENGTH)

    instance.distributorRes = Reservoir:new(DISTRIBUTOR_RES_CAPACITY)
    instance.auxiliaryRes = Reservoir:new(AUXILIARY_RES_CAPACITY)
    instance.cylinder = Cylinder:new(16, 700, 0.15, 0.2, 0.001)
    instance:addFeedPipe(MAIN_RES_CAPACITY)
    instance:addDistributor(DakoBv1:new(instance.brakePipe, instance.distributorRes, instance.auxiliaryRes, instance.cylinder))
    instance:addBrakeValve(DakoBs2:new(BS2_NOTCHES))

    return instance
end

return ZSSKC183
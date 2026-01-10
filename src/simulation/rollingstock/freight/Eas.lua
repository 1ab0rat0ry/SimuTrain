---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Reservoir.out"
---@type Cylinder
local Cylinder = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Cylinder.out"
---@type Vehicle
local Vehicle = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/rollingstock/Vehicle.out"
---@type DakoBv1
local DakoBv1 = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/distributor/dako/DakoBV1.out"

local LENGTH = 14.04
local DISTRIBUTOR_RES_CAPACITY = 0.009
local AUXILIARY_RES_CAPACITY = 0.1

---@class Eas: Vehicle
local Eas = {}

---@return Eas
function Eas:new()
    ---@type Eas
    local instance = Vehicle:new(LENGTH)

    instance.distributorRes = Reservoir:new(DISTRIBUTOR_RES_CAPACITY)
    instance.auxiliaryRes = Reservoir:new(AUXILIARY_RES_CAPACITY)
    instance.cylinder = Cylinder:new(16, 700, 0.15, 0.2, 0.001)
    instance:addDistributor(DakoBv1:new(instance.brakePipe, instance.distributorRes, instance.auxiliaryRes, instance.cylinder))

    return instance
end

return Eas
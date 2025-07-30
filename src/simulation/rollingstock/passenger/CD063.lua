---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Reservoir.out"
---@type Cylinder
local Cylinder = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Cylinder.out"
---@type Vehicle
local Vehicle = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/rollingstock/Vehicle.out"
---@type DakoBv1
local DakoBv1 = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/distributor/dako/DakoBV1.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/SimuTrain/src/utils/math/MathUtil.out"

local LENGTH = 24.5
local DISTRIBUTOR_RES_CAPACITY = 0.009
local AUXILIARY_RES_CAPACITY = 0.1
local CYLINDER_PISTON_AREA = MathUtil.getCircularAreaD(0.4064)

---@class Cd063: Vehicle
local Cd063 = {}

---@return Cd063
function Cd063:new()
    ---@type Cd063
    local instance = Vehicle:new(LENGTH)

    instance.distributorRes = Reservoir:new(DISTRIBUTOR_RES_CAPACITY, 601325)
    instance.auxiliaryRes = Reservoir:new(AUXILIARY_RES_CAPACITY, 601325)
    instance.cylinder = Cylinder:new(CYLINDER_PISTON_AREA, 315000, 2157, 100, 0.2, 0.001)
    instance:addFeedPipe()
    instance:addDistributor(DakoBv1:new(instance.brakePipe, instance.distributorRes, instance.auxiliaryRes, instance.cylinder))

    return instance
end

return Cd063
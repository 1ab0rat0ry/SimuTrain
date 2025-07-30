---@type Reservoir
local Reservoir = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Reservoir.out"
---@type Pipe
local Pipe = require "Assets/1ab0rat0ry/SimuTrain/src/simulation/brake/common/Pipe.out"
---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/SimuTrain/src/utils/math/MathUtil.out"

local PIPE_DIAMETER = 0.03175 --metres
local PIPE_CROSS_SECTION_AREA = math.pi * PIPE_DIAMETER ^ 2 / 4 --metres squared
local HOSE_LENGTH = 0.5 --metres

---@class Vehicle
---@field private length number
---@field private pipeCapcity number
---@field public brakePipe Pipe
---@field private feedPipe Reservoir
---@field private brakeValve table
---@field private distributor table
---@field private accelerator table
---@field public distributorRes Reservoir
---@field public auxiliaryRes Reservoir
---@field public controlRes Reservoir
---@field public cylinder Reservoir
local Vehicle = {
    length = 0,
    --brakeBlocks = 0,
    --maxPressureForcePerBlock = 0,
    --maxBrakeForce = 0,
    --TODO: brake block configurations and friction coefficient calculation

    brakePipe = {},
    feedPipe = nil,
    brakeValve = nil,
    distributor = nil,
    accelerator = nil,
    distributorRes = nil,
    auxiliaryRes = nil,
    controlRes = nil,
    cylinder = nil
}
Vehicle.__index = Vehicle

---@param length number
---@return Vehicle
function Vehicle:new(length)
    ---@type Vehicle
    local instance = {
        length = length,
        brakePipe = Pipe:new(length + 4 * HOSE_LENGTH, PIPE_DIAMETER),
        feedPipe = nil,
        brakeValve = nil,
        distributor = nil,
        accelerator = nil,
        distributorRes = nil,
        auxiliaryRes = nil,
        controlRes = nil,
        cylinder = nil
    }
    instance = setmetatable(instance, self)
    instance.brakePipe.pressure = 601325

    return instance
end

---Updates all systems and devices of vehicle.
---@param deltaTime number
function Vehicle:update(deltaTime)
    if self.brakeValve then self.brakeValve:update(deltaTime, self.feedPipe, self.brakePipe) end
    if self.distributor then self.distributor:update(deltaTime) end
    --if self.accelerator then self.accelerator:update(deltaTime, self.brakePipe, self.distributor) end
end

---Calculates brake force.
---@return number brake force expressed as number between `0` and `1`
function Vehicle:getBrakeControl()
    return MathUtil.inverseLerp(self.cylinder:getManoPressure(), 0.3, 3.8)
end

function Vehicle:setupBrakeSystem()
    
end

---@param mainResCapacity number
function Vehicle:addFeedPipe(mainResCapacity)
    self.feedPipe = Reservoir:new((self.length + 4 * HOSE_LENGTH) * PIPE_CROSS_SECTION_AREA + (mainResCapacity or 0))
end

---@param distributor table
function Vehicle:addDistributor(distributor)
    self.distributor = distributor
end

---@param brakeValve table
function Vehicle:addBrakeValve(brakeValve)
    self.brakeValve = brakeValve
end

---@param accelerator table
function Vehicle:addAccelerator(accelerator)
    self.accelerator = accelerator
end

return Vehicle
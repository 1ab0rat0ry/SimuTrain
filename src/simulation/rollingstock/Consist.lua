---@type ArrayList
local ArrayList = require "Assets/1ab0rat0ry/SimuTrain/src/utils/ArrayList.out"

local MIN_TIME_STEP = 0.04

---@class Consist
---@field public length number
---@field public vehicleCount number
---@field public vehicles ArrayList
local Consist = {
    length = 0,
    vehicleCount = 0,
    vehicles = ArrayList
}
Consist.__index = Consist

---@return Consist
function Consist:new()
    ---@type Consist
    local instance = {
        length = 0,
        vehicleCount = 0,
        vehicles = ArrayList:new()
    }
    instance = setmetatable(instance, self)

    return instance
end

---Adds vehicle to the end.
---@param vehicle Vehicle
function Consist:addVehicle(vehicle)
    if self.vehicleCount > 0 then
        self.vehicles.elements[self.vehicleCount].brakePipe:setNext(vehicle.brakePipe)
    end
    self.vehicleCount = self.vehicleCount + 1
    self.vehicles:add(vehicle)
end

---Updates all vehicles in consist and propagates brake pipe.
---@param deltaTime number
function Consist:update(deltaTime)
    local time = 0


    --while time < deltaTime do
    --    local fixedDeltaTime = deltaTime / math.ceil(deltaTime / MIN_TIME_STEP)

        ---@param vehicle Vehicle
        for _, vehicle in ipairs(self.vehicles.elements) do
            vehicle.brakePipe:update(deltaTime)
            vehicle:update(deltaTime)
        end

        --for _, vehicle in ipairs(self.vehicles.elements) do
        --    vehicle:update(deltaTime)
        --end
        --time = time + fixedDeltaTime
    --end
end

---Calculates brake force of the whole consist.
---@return number brake force as number between `0` and `1`
function Consist:getBrakeControl()
    local brakeControlSum = 0

    for _, vehicle in ipairs(self.vehicles.elements) do
        brakeControlSum = brakeControlSum + vehicle:getBrakeControl()
    end

    return brakeControlSum / self.vehicleCount
end

return Consist
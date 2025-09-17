--- @class Consist
--- @field public length number
--- @field public vehicleCount number
--- @field public vehicles table<number, Vehicle>
local Consist = {}
Consist.__index = Consist

--- @return Consist
function Consist:new()
    --- @type Consist
    local instance = {
        length = 0,
        vehicleCount = 0,
        vehicles = {}
    }

    return setmetatable(instance, self)
end

--- Adds vehicle to the end.
--- @param vehicle Vehicle
function Consist:addVehicle(vehicle)
    if self.vehicleCount > 0 then
        self.vehicles[self.vehicleCount].brakePipe:setRear(vehicle.brakePipe)
    end
    self.vehicleCount = self.vehicleCount + 1
    self.vehicles[self.vehicleCount] = vehicle
end

--- Updates all vehicles in consist and propagates brake pipe.
--- @param deltaTime number
function Consist:update(deltaTime)
    --- @param i number
    --- @param vehicle Vehicle
    for i, vehicle in ipairs(self.vehicles) do
        --- @type Vehicle
        local previousVehicle = self.vehicles[i - 1]

        if i > 1 and vehicle.feedPipe ~= nil and previousVehicle.feedPipe ~= nil then
            previousVehicle.feedPipe:averagePressure(vehicle.feedPipe)
        end
        vehicle.brakePipe:update(deltaTime)
        vehicle:update(deltaTime)
    end
end

--- @return Vehicle
function Consist:getFirstVehicle()
    return self.vehicles[1]
end

--- @return Vehicle
function Consist:getLastVehicle()
    return self.vehicles[self.vehicleCount]
end

--- Calculates brake force of the whole consist.
--- @return number brake force as number between `0` and `1`
function Consist:getBrakeControl()
    local brakeControlSum = 0

    for i = 1, self.vehicleCount do
        brakeControlSum = brakeControlSum + self.vehicles[i]:getBrakeControl()
    end

    return brakeControlSum / self.vehicleCount
end

return Consist
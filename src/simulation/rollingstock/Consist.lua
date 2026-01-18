---@class Consist
---@field public length number Physical length of consist.
---@field public vehicleCount number Number of vehicles.
---@field private vehicles table<number, Vehicle>
local Consist = {}
Consist.__index = Consist

---@return Consist
function Consist:new()
    ---@type Consist
    local instance = {
        length = 0,
        vehicleCount = 0,
        vehicles = {}
    }

    return setmetatable(instance, self)
end

---Updates all vehicles in consist and propagates brake pipe.
---@param deltaTime number
function Consist:update(deltaTime)
    ---@param i number
    ---@param vehicle Vehicle
    for i, vehicle in ipairs(self.vehicles) do
        ---@type Vehicle
        local prevVehicle = self.vehicles[i - 1]

        if i > 1 and vehicle.feedPipe and prevVehicle.feedPipe then
            prevVehicle.feedPipe:averagePressure(vehicle.feedPipe)
        end
        vehicle.brakePipe:update(deltaTime)
        vehicle:update(deltaTime)
    end
end

---Appends vehicle to the end.
---@param vehicle Vehicle
function Consist:addVehicle(vehicle)
    self:connectBrakePipe(self:getLastVehicle(), vehicle)
    self.vehicleCount = self.vehicleCount + 1
    self.vehicles[self.vehicleCount] = vehicle
end

---Splits consist at given index.
---Vehicles *1 .. index* stay in this consist,
---vehicles *index + 1 ..* end are returned as a new consist.
---@param index number
---@return Consist | nil
function Consist:splitAt(index)
    if index < 1 or index >= self.vehicleCount then return nil end

    local newConsist = Consist:new()
    local prev = self.vehicles[index]
    local next = self.vehicles[index + 1]

    if prev.brakePipe and next.brakePipe then
        prev.brakePipe.rearPipe = nil
        prev.brakePipe.rearCockOpen = false

        next.brakePipe.frontPipe = nil
        next.brakePipe.frontCockOpen = false
    end

    for i = index + 1, self.vehicleCount do
        newConsist:addVehicle(self.vehicles[i])
        self.vehicles[i] = nil
    end
    self.vehicleCount = index

    return newConsist
end

---@private
---@param front Vehicle
---@param rear Vehicle
function Consist:connectBrakePipe(front, rear)
    if self.vehicleCount <= 0 then return end
    front.brakePipe:setRear(rear.brakePipe)
end

---@return Vehicle
function Consist:getFirstVehicle()
    return self.vehicles[1]
end

---@return Vehicle
function Consist:getLastVehicle()
    return self.vehicles[self.vehicleCount]
end

---Calculates brake force of the whole consist.
---@return number brake force as number between `0` and `1`
function Consist:getBrakeControl()
    if self.vehicleCount <= 0 then return 0 end

    local brakeControlSum = 0

    for i = 1, self.vehicleCount do
        brakeControlSum = brakeControlSum + self.vehicles[i]:getBrakeControl()
    end

    return brakeControlSum / self.vehicleCount
end

return Consist
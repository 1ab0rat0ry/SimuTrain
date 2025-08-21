local ATM_PRESSURE = 101325
local NORMAL_TEMP = 273.15
--properties of air
local SPECIFIC_GAS_CONSTANT = 287.052874247
local HEAT_RATIO = 1.4
local HEAT_RATIO_INC = HEAT_RATIO + 1
local HEAT_RATIO_DEC = HEAT_RATIO - 1
local CRITICAL_PRESSURE_RATIO = (2 / HEAT_RATIO_INC) ^ (HEAT_RATIO / HEAT_RATIO_DEC)

---Represents reservoir containing air.
---@class Reservoir
---@field protected capacity number
---@field public pressure number
---@field protected temperature number
local Reservoir = {}
Reservoir.__index = Reservoir

---@overload fun(capacity: number): Reservoir
---@param capacity number Capacity of reservoir `[m ^ 3]`.
---@param pressure number Reservoir initial pressure `[Pa]`.
---@return Reservoir
function Reservoir:new(capacity, pressure)
    ---@type Reservoir
    local instance = {
        capacity = capacity,
        pressure = pressure or ATM_PRESSURE,
        temperature = NORMAL_TEMP
    }
    instance = setmetatable(instance, self)

    return instance
end

---Equalizes pressure between reservoirs.
---@param reservoir Reservoir
---@param area number
---@param deltaTime number
function Reservoir:equalize(reservoir, area, deltaTime)
    local inletRes, outletRes = reservoir, self

    if area == 0 or deltaTime == 0 then return end
    if self.pressure > reservoir.pressure then
        inletRes = self
        outletRes = reservoir
    end

    local massFlowRate = self:getMassFlowRate(inletRes.pressure, inletRes.temperature, outletRes.pressure, area)
    local capacitySum = inletRes.capacity + outletRes.capacity
    local avgPressure = (inletRes:getVolume() + outletRes:getVolume()) / capacitySum
    local targetMass = inletRes.getDensityFrom(avgPressure, NORMAL_TEMP) * inletRes.capacity
    local maxMassChange = inletRes:getMass() - targetMass
    local massChange = massFlowRate * deltaTime
    local actualMassChange = math.min(massChange, maxMassChange)

    inletRes:changeMass(-actualMassChange)
    outletRes:changeMass(actualMassChange)
end

---Vents pressure from reservoir into atmosphere.
---@param area number
---@param deltaTime number
function Reservoir:vent(area, deltaTime)
    if self.pressure < ATM_PRESSURE then return end

    local massFlowRate = self:getMassFlowRate(self.pressure, self.temperature, ATM_PRESSURE, area)
    local targetMass = self.getDensityFrom(ATM_PRESSURE, NORMAL_TEMP) * self.capacity
    local maxMassChange = self:getMass() - targetMass
    local massChange = massFlowRate * deltaTime
    local actualMassChange = math.min(massChange, maxMassChange)

    self:changeMass(-actualMassChange)
end

---@private
---@param inletPressure number
---@param inletTemp number
---@param outletPressure number
---@param area number
---@return number
function Reservoir:getMassFlowRate(inletPressure, inletTemp, outletPressure, area)
    local pressureRatio = outletPressure / inletPressure
    local baseComponent = area * inletPressure / math.sqrt(inletTemp)
    local correctionCoefM = self:getCorrectionCoefM(pressureRatio)
    local correctionCoefQ = self:getCorrectionCoefQ(pressureRatio)

    return baseComponent * correctionCoefM * correctionCoefQ
end

---@private
---@param pressureRatio number
---@return number
function Reservoir:getCorrectionCoefM(pressureRatio)
    if pressureRatio > CRITICAL_PRESSURE_RATIO then
        --subsonic flow
        local component1 = math.sqrt(2 * HEAT_RATIO / (SPECIFIC_GAS_CONSTANT * HEAT_RATIO_DEC))
        local component2 = pressureRatio ^ (2 / HEAT_RATIO)
        local component3 = pressureRatio ^ (HEAT_RATIO_INC / HEAT_RATIO)

        return component1 * math.sqrt(component2 - component3)
    end

    --supersonic flow
    return math.sqrt(HEAT_RATIO / SPECIFIC_GAS_CONSTANT * (2 / HEAT_RATIO_INC) ^ (HEAT_RATIO_INC / HEAT_RATIO_DEC))
end

---@private
---@param pressureRatio number
---@return number
function Reservoir:getCorrectionCoefQ(pressureRatio)
    return 0.8414 - 0.1002 * pressureRatio + 0.8415 * pressureRatio ^ 2 - 3.9 * pressureRatio ^ 3 + 4.6001 * pressureRatio ^ 4 - 1.6827 * pressureRatio ^ 5
end

--- - source: [https://en.wikipedia.org/wiki/Viscosity#Air](https://en.wikipedia.org/wiki/Viscosity#Air)
---@return number
function Reservoir:getDynamicViscosity()
    return 2.791 * 10 ^ -7 * self.temperature ^ 0.7355
end

---@param massChange number
function Reservoir:changeMass(massChange)
    self.pressure = self.pressure + massChange * SPECIFIC_GAS_CONSTANT * self.temperature / self.capacity
end

---Get reservoir pressure as displayed on manometer.
---@return number Manometer pressure `[bar]`.
function Reservoir:getManoPressure()
    return math.max(0, self.pressure - ATM_PRESSURE) * 1e-5
end

---Get mass of gas in reservoir.
---@return number
function Reservoir:getMass()
    return self:getDensity() * self.capacity
end

---Get volume of gas in reservoir.
---@return number
function Reservoir:getVolume()
    return self.pressure * self.capacity
end

---Get density of gas in reservoir.
function Reservoir:getDensity()
    return self.pressure / (SPECIFIC_GAS_CONSTANT * self.temperature)
end

---Set pressure according to new density.
---@param density number
function Reservoir:setDensity(density)
    self.pressure = density * SPECIFIC_GAS_CONSTANT * self.temperature
end

---@param pressure number
---@param temperature number
function Reservoir.getDensityFrom(pressure, temperature)
    return pressure / (SPECIFIC_GAS_CONSTANT * temperature)
end

Reservoir.atmosphere = Reservoir:new(1e3)

return Reservoir
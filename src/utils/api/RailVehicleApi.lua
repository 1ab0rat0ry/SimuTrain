---@class RailVehicleApi These functions apply to the base class of all rail vehicles.
local RailVehicleApi = {}

local call = Call

---Is the rail vehicle controlled by the player.
---@return number If the train is player controlled `1`, if the train is AI controlled `0`.
function RailVehicleApi.getIsPlayer() return call("GetIsPlayer") end

---Get the rail vehicle's current speed.
---@return number The speed in metres per second.
function RailVehicleApi.getSpeed() return call("GetSpeed") end

---Get the rail vehicle's acceleration.
---@return number The acceleration in metres per second squared.
function RailVehicleApi.getAcceleration() return call("GetAcceleration") end

---Get the total mass of the rail vehicle including cargo.
---@return number The mass in kilograms.
function RailVehicleApi.getTotalMass() return call("GetTotalMass") end

---Get the total mass of the entire consist including cargo.
---@return number The mass in kilograms.
function RailVehicleApi.getConsistTotalMass() return call("GetConsistTotalMass") end

---Get the consist length.
---@return number The length in metres.
function RailVehicleApi.getConsistLength() return call("GetConsistLength") end

---Get the gradient at the front of the consist.
---@return number The gradient as a percentage.
function RailVehicleApi.getGradient() return call("GetGradient") end

---Get the curvature (radius of curve) at the front of the consist.
---@return number The radius of the curve in metres.
function RailVehicleApi.getCurvature() return call("GetCurvature") end

---Get the curvature relative to the front of the vehicle.
---@param displacement number If positive, returns curvature this number of metres ahead of the front of the vehicle. If negative, returns curvature this number of metres behind the rear of the vehicle.
---@return number The radius of the curve in metres `positive` if curving to the right, `negative` if curving to the left, relative to the way the vehicle is facing.
function RailVehicleApi.getCurvatureAhead(displacement) return call("GetCurvatureAhead", displacement) end

---Get the rail vehicle's number.
---@return number The rail vehicle number.
function RailVehicleApi.getRvNumber() return call("GetRVNumber") end

---Set the rail vehicle's number (used for changing destination boards).
---@param number number The new number for the vehicle.
function RailVehicleApi.setRvNumber(number) call("SetRVNumber", number) end

---Send a message to the next or previous rail vehicle in the consist.
---Calls the script function `OnConsistMessage(message, argument, direction)` in the next or previous rail vehicle.
---@param message number The ID of a message to send (IDs `0` to `100` are reserved, please use IDs greater than `100`).
---@param argument string Message argument.
---@param direction number Use `0` to send a message to the vehicle in front, `1` to send a message to the vehicle behind.
---@return number If there was a next/previous rail vehicle `1`.
function RailVehicleApi.sendConsistMessage(message, argument, direction) return call("SendConsistMessage", message, argument, direction) end

---Get the next restrictive signal's distance and state.
---@param direction number Optional. `0` = forwards, `1` = backwards. Defaults to `0`.
---@param minDistance number Optional. How far ahead in metres to start searching. Defaults to `0`.
---@param maxDistance number Optional. How far ahead in metres to stop searching. Defaults to `10 000`.
---@return number, number, number, number Param 1: `1` = nothing found, `0` = end of track, `>0` = signal found; Param 2: Basic signal state: `-1` = invalid, `1` = warning, `2` = red; Param 3: Distance in metres to signal; Param4: 2D map's "pro" signal state for more detailed aspect information. `-1` = invalid, `1` = yellow, `2` = double-yellow, `3` = red, `10` = flashing-yellow, `11` = flashing-double-yellow.
function RailVehicleApi.getNextRestrictiveSignal(direction, minDistance, maxDistance) return call("GetNextRestrictiveSignal", direction, minDistance, maxDistance) end

---Set a failure value on the train brake system for this vehicle.
---@param name string The name of the failure type. Either one of `BRAKE_FADE` (the proportion of brake power lost due to fade in the braking as a result of excess heat) or `BRAKE_LOCK` (the proportion of max force the brake is stuck at due to locking on the wheel).
---@param value number The value of the failure dependent on failure type.
function RailVehicleApi.setBrakeFailureValue(name, value) call("SetBrakeFailureValue", name, value) end

---Get the type, limit and distance to the next speed limit.
---@param direction number Optional. `0` = forwards, `1` = backwards. Defaults to `0`.
---@param minDistance number Optional. How far ahead in metres to start searching. Defaults to `0`.
---@param maxDistance number Optional. How far ahead in metres to stop searching. Defaults to `10 000`.
---@return number, number, number Param 1: `-1` = nothing found, `0` = end of track, `1` = track speed limit (no signage), `2` = track speed limit sign, `3` = track speed limit; Param 2: Restriction in metres per second; Param 3: Distance in metres to speed limit.
function RailVehicleApi.getNextSpeedLimit(direction, minDistance, maxDistance) return call("GetNextSpeedLimit", direction, minDistance, maxDistance) end

---Get the current speed limit for the consist.
---@param component number Optional. `0` = return current limit, `1` = return separate track and signal limit. Defaults to `0`.
---@return number, number If `component` is set to `0`, then a single value is returned. Otherwise, two values are returned for track and signal limits respectively.
function RailVehicleApi.getCurrentSpeedLimit(component) return call("GetCurrentSpeedLimit", component) end

---Get the class of the consist.
---@return number eTrainTypeSpecial = `0`, eTrainTypeLightEngine = `1`, eTrainTypeExpressPassenger = `2`, eTrainTypeStoppingPassenger = `3`, eTrainTypeHighSpeedFreight = `4`, eTrainTypeExpressFreight = `5`, eTrainTypeStandardFreight = `6`, eTrainTypeLowSpeedFreight = `7`, eTrainTypeOtherFreight = `8`, eTrainTypeEmptyStock = `9`, eTrainTypeInternational = `10`
function RailVehicleApi.getConsistType() return call("GetConsistType") end

--TODO verify
---Evaluates if camera is near this vehicle ( < 4 km).
---@return boolean
function RailVehicleApi.getIsNearCamera() return call("GetIsNearCamera") end

--TODO verify
---Evaluates if the vehicle is in a tunnel.
---@return boolean
function RailVehicleApi.getIsInTunnel() call("GetIsInTunnel") end

return RailVehicleApi
--Weather controller: The weather control module.

---Get the current type of precipitation.
---@return number Precipitation type: rain = `0`, sleet = `1`, hail = `2`, snow = `3`.
function ApiUtil.getPrecipitationType() return sysCall("WeatherController:GetCurrentPrecipitationType") end

---Get the density of the precipitation.
---@return number Float value between `0` and `1` for the density of precipitation.
function ApiUtil.getPrecipitationDensity() return sysCall("WeatherController:GetPrecipitationDensity") end

---Get the speed of the precipitation.
---@return number The vertical fall speed of precipitation in metres per second.
function ApiUtil.getPrecipitationSpeed() return sysCall("WeatherController:GetPrecipitationSpeed") end


--Camera manger: The camera control module.

---Switch to a named camera. The camera can be any of the standard cameras or a user-defined camera.
---
---`CabCamera:` the cab interior camera (as assigned to `Key 1`).
---
---`ExternalCamera:` the exterior train tracking camera (as assigned to `Key 2`).
---
---`HeadOutCamera:` the head out camera (as assigned to `Shift + Key 2`).
---
---`TrackSideCamera:` the trackside camera (as assigned to `Key 4`).
---
---`CarriageCamera:` the carriage interior camera (as assigned to `Key 5`).
---
---`CouplingCamera:` the coupling camera (as assigned to `Key 6`).
---
---`YardCamera:` the top-down camera view (as assigned to `Key 7`).
---
---`FreeCamera:` the free camera (as mapped to `Key 8`).
---@param name string The name of the camera.
---@param time number The time in seconds before reverting back to previous camera. Use `0` for no revert.
function ApiUtil.activateCamera(name, time) sysCall("CameraManager:ActivateCamera", name, time) end

---Have the camera look at an objection. If `name` is a rail vehicle number, then the camera will look at that rail vehicle.
---If the `name` is that of a named object, then only the free camera will look at the object.
---@param name string The name of the object to look at.
---@return number If the named object was found `1`, otherwise `0`.
function ApiUtil.lookAt(name) return sysCall("CameraManager:LookAt", name) end

---Move the camera to a location. Only available for the free camera.
---@param longitude number The longitude of the position.
---@param latitude number The latitude of the position.
---@param height number The height above sea level.
---@return number If the camera could move to the location `1`, otherwise `0`.
function ApiUtil.jumpTo(longitude, latitude, height) return sysCall("CameraManager:JumpTo", longitude, latitude, height) end
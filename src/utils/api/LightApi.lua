--Light: These functions concern the operation of Spot and Point lights on rail vehicles.

---Turn on the light.
---@param name string Light name.
function ApiUtil.activateLight(name) call(name.."Activate", 1) end

---Turn off the light.
---@param name string Light name.
function ApiUtil.activateLight(name) call(name.."Activate", 0) end

---Set the colour of the light.
---@param name string Light name.
---@param red number Range `0` to `1`.
---@param green number Range `0` to `1`.
---@param blue number Range `0` to `1`.
function ApiUtil.setLightColour(name, red, green, blue) call(name.."SetColour", red, green, blue) end

---Get the colour of the light.
---@param name string Light name.
---@return number, number, number The `red`, `green` and `blue` components of the colour as floats of range `0` to `1`.
function ApiUtil.getLightColour(name) return call(name.."GetColour") end

---Set the range of the light.
---@param name string Light name.
---@param range number The range of the light in metres.
function ApiUtil.setLightRange(name, range) call(name.."SetRange", range) end

---Get the range of the light.
---@param name string Light name.
---@return number The range of the light in metres.
function ApiUtil.getLightRange(name) return call(name.."GetRange") end

---Set the umbra angle (full beam angle) of a spot light.
---@param name string Light name.
---@param angle number The angle of the inner cone in degrees.
function ApiUtil.setUmbraAngle(name, angle) call(name.."SetUmbraAngle", angle) end

---Get the umbra angle (full beam angle) of a spot light.
---@param name string Light name.
---@return number The angle of the inner cone in degrees.
function ApiUtil.getUmbraAngle(name) return call(name.."GetUmbraAngle") end

---Set the penumbra angle (beam fall off angle) of a spot light.
---@param name string Light name.
---@param angle number The angle of the outer cone in degrees.
function ApiUtil.setPenumbraAngle(name, angle) call(name.."SetPenumbraAngle", angle) end

---Get the penumbra angle (beam fall off angle) of a spot light.
---@param name string Light name.
---@return number The angle of the outer cone in degrees.
function ApiUtil.getPenumbraAngle(name) return call(name.."GetUmbraAngle") end
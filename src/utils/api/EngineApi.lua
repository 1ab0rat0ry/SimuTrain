--Engine: These functions are also available to Engines specifically.

--TODO verify
---Get the proportion of tractive effort being used.
---@return number The proportion of tractive effort between `0%` and `100%`.
function ApiUtil.getTractiveEffort() return call("GetTractiveEffort") end

---Is this the player controlled primary engine.
---@return number If this is the engine the player is controlling `1`, otherwise `0`.
function ApiUtil.getIsEngineWithKey() return call("GetIsEngineWithKey") end

---Evaluate whether this engine is disabled.
---@return number If this engine is disabled `1`, if not `0`.
function ApiUtil.getIsDeadEngine() return call("GetIsDeadEngine") end

---Set the proportion of normal power a diesel unit should output.
---@param index number Index of the power unit (use `-1` for all power units).
---@param value number The proportion of normal power output between `0` and `1`.
function ApiUtil.setPowerProportion(index, value) call("SetPowerProportion", index, value) end

---Get the proportion of full firebox mass.
---@return number The mass of the firebox as a proportion of max in the range `0` to `1`.
function ApiUtil.getFireboxMass() return call("GetFireboxMass") end


--Emitter: These functions are related to particle emitter aspects involved in rail vehicles.

---Activate an emitter.
---@param name string Emitter name.
function ApiUtil.activateEmitter(name) call(name..":SetEmitterActive", 1) end

---Deactivate an emitter.
---@param name string Emitter name.
function ApiUtil.deactivateEmitter(name) call(name..":SetEmitterActive", 0) end

--TODO verify
---Get whether the emitter is active.
---@param name string Emitter name
---@return number If active `1`, if not `0`.
function ApiUtil.isActiveEmitter(name) return call(name.."GetEmitterActive") end

---Restart the emitter.
---@param name string Emitter name
function ApiUtil.restartEmitter(name) call(name.."RestartEmitter") end

---Set the emitter colour multiplier.
---@param name string Emitter name
---@param red number Range `0` to `1`.
---@param green number Range `0` to `1`.
---@param blue number Range `0` to `1`.
---@param alpha number Optional. Range `0` to `1`.
function ApiUtil.setEmitterColour(name, red, green, blue, alpha) call(name.."SetEmitterColour", red, green, blue, alpha) end

---Get the current emitter colour.
---@param name string Emitter name
---@return number, number, number, number Colour components: `red`, `green`, `blue`, `alpha` as floats of range `0` to `1`.
function ApiUtil.getEmitterColour(name) return call(name..":GetEmitterColour") end

---Set the emitter rate multiplier.
---@param name number Emitter name
---@param multiplier number Use `1` for default rate.
function ApiUtil.setEmitterRate(name, multiplier) call(name.."SetEmitterRate", multiplier) end

---Get the emitter rate multiplier. `1` is default, `0` is no emission.
---@param name string Emitter name
---@return number The emitter rate.
function ApiUtil.getEmitterRate(name) return call(name.."GetEmitterRate") end

---Multiply the initial velocity by a given value. Default value is `1`.
---@param name string Emitter name
---@param multiplier number Multiplier to scale X, Y, Z velocity components.
function ApiUtil.setEmitterVelocityMultiplier(name, multiplier) call(name.."SetInitialVelocityMultiplier", multiplier) end
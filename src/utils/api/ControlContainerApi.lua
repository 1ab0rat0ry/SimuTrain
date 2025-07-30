--Control container: These functions are related to the Control Container aspect of rail vehicles.

--TODO verify
---Evaluates whether a control with a specific name exists.
---@param name string Name of the control.
---@param index number Optional, defaults to `0`. The index of the control (usually `0` unless there are multiple controls with the same name).
---@return number If the control exists `1` otherwise `0`.
function ApiUtil.controlExists(name, index) return call("ControlExists", name, index or 0) end

---Get the value for a control.
---@param name string Name of the control.
---@param index number Optional, defaults to `0`. The index of the control (usually `0` unless there are multiple controls with the same name).
---@return number The value for the control.
function ApiUtil.getControlValue(name, index) return call("GetControlValue", name, index or 0) end

---Set a value for a control.
---@param name string Name of the control.
---@param index number Optional, defaults to `0`. The index of the control (usually `0` unless there are multiple controls with the same name).
function ApiUtil.setControlValue(name, value, index) call("SetControlValue", name, index or 0, value) end

---Get the minimum value for a control.
---@param name string Name of the control.
---@param index number Optional, defaults to `0`. The index of the control (usually `0` unless there are multiple controls with the same name).
---@return number The control's minimum value.
function ApiUtil.getControlMinimum(name, index) return call("GetControlMinimum", name, index or 0) end

---Get the maximum value for a control.
---@param name string Name of the control.
---@param index number Optional, defaults to `0`. The index of the control (usually `0` unless there are multiple controls with the same name).
---@return number The control's maximum value.
function ApiUtil.getControlMaximum(name, index) return call("GetControlMaximum", name, index or 0) end

--TODO verify
---Evaluate whether or not a control is locked.
---@param name string Name of the control.
---@param index number Optional, defaults to `0`. The index of the control (usually `0` unless there are multiple controls with the same name).
---@return number If unlocked `0`, if locked `1`.
function ApiUtil.isControlLocked(name , index) return call("IsControlLocked", name, index or 0) end

---Locks a control so the user can no longer affect it.
---@param name string Name of the control.
---@param index number Optional, defaults to `0`. The index of the control (usually `0` unless there are multiple controls with the same name).
function ApiUtil.lockControl(name, index) return call("LockControl", name, index or 0, true) end

---Unlocks a control so the user can affect it.
---@param name string Name of the control.
---@param index number Optional, defaults to `0`. The index of the control (usually `0` unless there are multiple controls with the same name).
function ApiUtil.unlockControl(name, index) return call("LockControl", name, index or 0, false) end

---Get the normalised value of a wiper animation current frame.
---@param index number Index of the wiper pair.
---@param wiper string The wiper to get the value of in the wiper pair.
---@return number A value between `0` and `1` of the wiper's current position in the animation.
function ApiUtil.getWiperValue(index, wiper) return call("GetWiperValue", index, wiper) end

---	Set the normalised value of a wiper's animation.
---@param index number Index of the wiper pair.
---@param wiper string The wiper to get the value of in the wiper pair.
---@param value number The value to set the wiper to.
function ApiUtil.getWiperValue(index, wiper, value) call("GetWiperValue", index, wiper, value) end

---Get the number of wiper pairs this control container has.
---@return number Number of wiper pairs in the control container.
function ApiUtil.getWiperPairCount() return call("GetWiperPairCount") end
--Sound: These functions are related to the Sound Component aspect of rail vehicles.

---Set a parameter on an audio proxy.
---@param name string Name of the parameter.
---@param value number
function ApiUtil.setParameter(name, value) call("SetParameter", name, value) end
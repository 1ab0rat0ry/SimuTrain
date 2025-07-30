---@class RenderApi These functions relate to the RenderComponent which encompases the model, nodes and animations.
local RenderApi = {}

local call = Call

---Activate a node in a model.
---@param name string Name of the node (use "all" for all nodes).
function RenderApi.activateNode(name) call("ActivateNode", name, 1) end

---Deactivate a node in a model.
---@param name string Name of the node (use "all" for all nodes).
function RenderApi.deactivateNode(name) call("ActivateNode", name, 0) end

---Add time to an animation.
---@param name string Name of the animation.
---@param increment number The amount of time in seconds, either positive or negative.
---@return number The remaining time in the animation.
function RenderApi.addTime(name, increment) return call("Add", name, increment) end

---Reset the animation to time = `0`.
---@param name string Name of the animation.
function RenderApi.reset(name) call("Reset", name) end

---Set the time of an animation.
---@param name string Name of the animation.
---@param time number The amount of time in seconds, either positive or negative.
---@return number The remaining time in the animation.
function RenderApi.setTime(name, time) return call("SetTime", name, time) end

return RenderApi
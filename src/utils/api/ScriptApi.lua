---@class ScriptApi These functions are available only to scripted entities.
local ScriptApi = {}

local call = Call

---Request script to get update call once per frame.
function ScriptApi.beginUpdate() call("BeginUpdate") end

---	Request script to end update call once per frame.
function ScriptApi.endUpdate() call("EndUpdate") end

---@return number Integer of the simulation time in seconds.
function ScriptApi.getSimulationTime() return call("GetSimulationTime") end

---@return number If the controls are in expert mode `1` otherwise `0`.
function ScriptApi.isExpertMode() return call("IsExpertMode") end

return ScriptApi
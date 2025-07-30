---@class PosOriApi These functions are related to the position and/or orientation of a component.
local PosOriApi = {}

local call = Call

--TODO add name param
---Get the position in the current world frame of the object (local coordinates are local to a moving origin centred on the camera's current tile).
---@return number, number, number The position x, y, z in metres relative to the origin.
function PosOriApi.getNearPosition() return call("getNearPosition") end

---Set the position in the current world frame of the object (local coordinates are local to a moving origin centred on the camera's current tile).
---@param x number The x coordinate.
---@param y number The y coordinate.
---@param z number The z coordinate.
function PosOriApi.setNearPosition(x, y, z) call("setNearPosition", x, y, z) end

return PosOriApi
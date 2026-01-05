---@class Timer
---@field private lastReset number
---@field private delay number
local Timer = {}
Timer.__index = Timer

---@param delay number
---@return Timer
function Timer:new(delay)
    ---@type Timer
    local obj = {
        lastReset = os.clock(),
        delay = delay or 0
    }
    obj = setmetatable(obj, self)

    return obj
end

---Returns true if more time has passed since last reset than delay.
---@param delay number
---@return boolean
function Timer:hasFinished(delay)
    return self:getTime() >= (delay or self.delay)
end

---Resets timer to zero.
function Timer:reset()
    self.lastReset = os.clock()
end

---Return time since last reset.
---@return number
function Timer:getTime()
    return os.clock() - self.lastReset
end

return Timer
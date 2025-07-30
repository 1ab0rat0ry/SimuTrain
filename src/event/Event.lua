---@class Event
---@field listeners table<function>
local Event = {
    listeners = {},
    isCancelled = false
}
Event.__index = Event

---Create a new Event.
---@return Event
function Event:new()
    local instance = {isCancelled = false}
    setmetatable(instance, self)

    return instance
end

---Register a function as listener to event.
---@param listener function
function Event:registerListener(listener)
    self.listeners[table.getn(self.listeners) + 1] = listener
end

--[[function Event:unregisterListener(listener)
    for i, v in ipairs(self.listeners) do
        if v == listener then
            self.listeners[i] = nil
            return
        end
    end
end]]

---Invoke the event. Calls all registered listeners.
---@param context any
function Event:invoke(context)
    for _, v in ipairs(self.listeners) do
        v(context)
    end
end

function Event:cancel()
    self.isCancelled = true;
end
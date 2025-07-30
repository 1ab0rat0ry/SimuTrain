---@type Event
local Event = require "Assets/1ab0rat0ry/RWLab/event/Event.out"

---@class Events
---@field Initialise Event
---@field Update Event
---@field ControlValueChange Event
---@field ConsistMessage Event
---@field CustomSignalMessage Event
---@field CameraEnter Event
---@field CameraLeave Event
local Events = {
    Initialise = Event:new(),
    Update = Event:new(),
    ControlValueChange = Event:new(),
    ConsistMessage = Event:new(),
    CustomSignalMessage = Event:new(),
    CameraEnter = Event:new(),
    CameraLeave = Event:new()
}

return Events
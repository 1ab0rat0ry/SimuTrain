---@class Logger
local Logger = {
    log = true,
    debug = true,
    file = "CD460.log"
}

---@param log boolean
---@param file string
function Logger:new(log, file)
    local o = setmetatable({}, self)
    self.__index = self
    o.log = log
    o.file = file or "CD460.log"
    return o
end

---@param message string
function Logger:info(message)
    if not self.log then return end
    local file = io.open(self.file, "a")

    file:write(message.."\n")
    file:close()
end

return Logger
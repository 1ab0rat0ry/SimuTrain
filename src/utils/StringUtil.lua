---@class StringUtil
local StringUtil = {}

---@param text string
---@param delimiter string
---@return table<number, string>
function StringUtil.split(text, delimiter)
    local result = {}
    local searchFrom = 1
    local occurenceStart, occurenceEnd = string.find(text, delimiter, searchFrom, true)

    while occurenceStart ~= nil do
        table.insert(result, string.sub(text, searchFrom, occurenceStart - 1))
        searchFrom = occurenceEnd + 1
        occurenceStart, occurenceEnd = string.find(text, delimiter, searchFrom, true)
    end
    table.insert(result, string.sub(text, searchFrom))

    return result
end

return StringUtil
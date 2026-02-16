---@type StringUtil
local StringUtil = require "Assets/1ab0rat0ry/SimuTrain/src/utils/StringUtil.out"

local VERSION = "0.1.1"

---@class SimuTrain
local SimuTrain = {}

---@param id string
local function isNumericIdentifier(id)
    return id ~= "" and string.find(id, "^%d+$") ~= nil
end

---@param version string
---@return table
local function parseSemver(version)
    --strip build metadata
    local plusIndex = string.find(version, "+", 1, true)

    if plusIndex then
        version = string.sub(version, 1, plusIndex - 1)
    end

    --split prerelease
    local dashIndex = string.find(version, "-", 1, true)
    ---@type string | nil
    local prerelease

    if dashIndex then
        prerelease = string.sub(version, dashIndex + 1)
        version = string.sub(version, 1, dashIndex - 1)
    end

    --split version into major, minor and patch
    ---@type string
    local _, _, major, minor, patch = string.find(version, "^(%d+)%.(%d+)%.(%d+)$")
    ---@type table<number, string> | nil
    local prereleaseIds

    if not major then return nil end
    if prerelease and prerelease ~= "" then
        prereleaseIds = StringUtil.split(prerelease, ".")
    end

    return {
        major = tonumber(major),
        minor = tonumber(minor),
        patch = tonumber(patch),
        pre = prereleaseIds
    }
end

---@param a number
---@param b number
---@return number
local function compare(a, b)
    if a < b then return -1 end
    if a > b then return 1 end

    return 0
end

---@param aIds table<number, string>
---@param bIds table<number, string>
local function comparePrelease(aIds, bIds)
    if aIds == nil and bIds == nil then return 0 end
    if aIds == nil then return 1 end
    if bIds == nil then return -1 end

    local aLength = table.getn(aIds)
    local bLength = table.getn(bIds)
    local minLength = math.min(aLength, bLength)

    for i = 1, minLength do
        local aId = aIds[i]
        local bId = bIds[i]

        local aIsNumeric = isNumericIdentifier(aId)
        local bIsNumeric = isNumericIdentifier(bId)

        if aIsNumeric and bIsNumeric then
            local result = compare(tonumber(aId), tonumber(bId))

            if result ~= 0 then return result end
        elseif aIsNumeric and (not bIsNumeric) then return -1
        elseif (not aIsNumeric) and bIsNumeric then return 1
        else
            if aId < bId then return -1 end
            if aId > bId then return 1 end
        end
    end

    if aLength < bLength then return -1 end
    if aLength > bLength then return 1 end

    return 0
end

---@return string
function SimuTrain.getVersion()
    return VERSION
end

---@param a string
---@param b string
---@return number
function SimuTrain.compareVersion(a, b)
    local aParsed = parseSemver(a)
    if not aParsed then return nil end

    local bParsed = parseSemver(b)
    if not bParsed then return nil end

    local result = compare(aParsed.major, bParsed.major)
    if result ~= 0 then return result end

    result = compare(aParsed.minor, bParsed.minor)
    if result ~= 0 then return result end

    result = compare(aParsed.patch, bParsed.patch)
    if result ~= 0 then return result end

    return comparePrelease(aParsed.pre, bParsed.pre)
end

---@param required string
---@return boolean
function SimuTrain.isVersionAtLeast(required)
    local result = SimuTrain.compareVersion(VERSION, required)

    if not result then return nil end

    return result >= 0
end

return SimuTrain
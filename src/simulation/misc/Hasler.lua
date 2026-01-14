---@type MathUtil
local MathUtil = require "Assets/1ab0rat0ry/SimuTrain/src/utils/math/MathUtil.out"
---@type Timer
local Timer = require "Assets/1ab0rat0ry/SimuTrain/src/utils/Timer.out"

---@class Hasler
---@field private targetSpeed number
---@field private speed number
---@field private updateTimer Timer
local Hasler = {}
Hasler.__index = Hasler

function Hasler:new()
    ---@type Hasler
    local instance = {
        targetSpeed = 0,
        speed = 0,
        updateTimer = Timer:new(0.8)
    }

    return setmetatable(instance, self)
end

function Hasler:update(deltaTime, realSpeed)
    if self.updateTimer:hasFinished() then
        local noise = math.random() > 0.7 and math.random() - 0.5 or 0

        self.targetSpeed = realSpeed > 0.1 and math.max(0, realSpeed + noise) or 0
        self.updateTimer:reset()
    end

    if math.abs(self.targetSpeed - self.speed) > 0.1 then
        self.speed = MathUtil.towards(self.speed, self.targetSpeed, 10 * deltaTime)
    end
    Call("SetControlValue", "HaslerSpeed", 0, self.speed)
end

return Hasler
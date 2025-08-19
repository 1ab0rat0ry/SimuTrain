---@class MathUtil
local MathUtil = {}

local INF = 1 / 0

---@param value number
---@return boolean true if `value` is NaN, false otherwise
function MathUtil.isNan(value)
    -- NaN is the only value that is not equal to itself
    return value ~= value
end

---@param value number
---@return boolean true if `value` is infinite, false otherwise
function MathUtil.isInf(value)
    return value == INF or value == -INF
end

---@param num number
---@param min number
---@param max number
---@return number between `min` inclusive and `max` inclusive
function MathUtil.clamp(num, min, max)
    if num < min then return min
    elseif num > max then return max
    end

    return num
end

---@param num number
---@return number between `0` inclusive and `1` inclusive
function MathUtil.clamp01(num)
    if num < 0 then return 0
    elseif num > 1 then return 1
    end

    return num
end

---@param num number between `0` inclusive and `1` inclusive
---@param min number
---@param max number
---@return number between `min` inclusive and `max` inclusive
function MathUtil.lerp(num, min, max)
    return min + (max - min) * MathUtil.clamp01(num)
end

---@param num number
---@param min number
---@param max number
---@return number between `min` inclusive and `max` inclusive
function MathUtil.lerpUnclamped(num, min, max)
    return min + (max - min) * num
end

---@param num number
---@param min number
---@param max number
---@return number between 0 inclusive and 1 inclusive
function MathUtil.inverseLerp(num, min, max)
    if min == max then return 0 end
    return MathUtil.clamp01((num - min) / (max - min))
end

---Maps `num` from input range to output range.
---@param num number
---@param inMin number
---@param inMax number
---@param outMin number
---@param outMax number
---@return number
function MathUtil.map(num, inMin, inMax, outMin, outMax)
    if inMax == inMin then return outMin end
    return outMin + (outMax - outMin) / (inMax - inMin) * (num - inMin)
end

---Steps `num` towards `target` without overshooting it.
---@param num number
---@param target number
---@param step number
---@return number
function MathUtil.towards(num, target, step)
    if step <= 0 then return num end
    if math.abs(target - num) <= step then return target end

    return num + MathUtil.sign(target - num) * step
end

---@param num number
---@param min number
---@param max number
function MathUtil.smoothstep(num, min, max)
    num = MathUtil.clamp01((num - min) / (max - min));

    return num * num * (3 - 2 * num);
end

---@param num number
---@param min number
---@param max number
function MathUtil.smootherstep(num, min, max)
    num = MathUtil.clamp01((num - min) / (max - min));

    return num * num * num * (num * (6 * num - 15) + 10);
end

---Gradually changes value towards target using critical damping.
--- - source: Game Programming Gems 4, page 99
---@param current number
---@param target number
---@param velocity number
---@param smoothTime number
---@param deltaTime number
---@param maxSpeed number
function MathUtil.smoothDamp(current, target, velocity, smoothTime, deltaTime, maxSpeed)
    if maxSpeed == nil then maxSpeed = 1e10 end

    smoothTime = math.max(0.0001, smoothTime)

    local omega = 2 / smoothTime
    local x = omega * deltaTime
    local exp = 1 / (1 + x + 0.48 * x ^ 2 + 0.235 * x ^ 3)
    local change = current - target
    local originalTo = target
    local maxChange = maxSpeed * smoothTime

    change = MathUtil.clamp(change, -maxChange, maxChange)
    target = current - change

    local temp = (velocity + omega * change) * deltaTime
    velocity = (velocity - omega * temp) * exp
    local output = target + (change + temp) * exp

    if ((originalTo - current > 0) == (output > originalTo)) then
        output = originalTo
        velocity = (output - originalTo) / deltaTime
    end

    return output, velocity
end

---@param num number
---@return number for negative numbers `-1`, for zero `0`, for positive numbers `1`
function MathUtil.sign(num)
    return num > 0 and 1 or num < 0 and -1 or 0
end

---@param num number
---@param places number to which decimal place round `num`, leave empty or set to `0` for rounding to ones
---@return number rounded number
function MathUtil.round(num, places)
    local factor = 10 ^ (places or 0)
    return math.floor(num * factor + 0.5) / factor
end

return MathUtil
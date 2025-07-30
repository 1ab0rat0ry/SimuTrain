---@class MathUtil
local MathUtil = {
    INF = 1 / 0,
    NAN = 0 / 0
}

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

---@param factor number between `0` inclusive and `1` inclusive
---@param min number
---@param max number
---@return number between `min` inclusive and `max` inclusive
function MathUtil.lerp(factor, min, max)
    return min + (max - min) * MathUtil.clamp(factor, 0, 1)
end

---@param num number
---@param min number
---@param max number
---@return number between 0 inclusive and 1 inclusive
function MathUtil.inverseLerp(num, min, max)
    return MathUtil.clamp((num - min) / (max - min), 0, 1)
end

---Maps `num` from input range to output range.
---@param num number
---@param inMin number
---@param inMax number
---@param outMin number
---@param outMax number
---@return number
function MathUtil.map(num, inMin, inMax, outMin, outMax)
    return outMin + (outMax - outMin) / (inMax - inMin) * (num - inMin)
end

---Steps `num` towards `target` without overshooting it.
---@param num number
---@param target number
---@param step number
---@return number
function MathUtil.towards(num, target, step)
    return MathUtil.clamp(target, num - step, num + step)
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

---Calculates circular area with given `radius`.
---@param radius number
---@return number
function MathUtil.getCircularArea(radius)
    return math.pi * radius ^ 2
end

---Calculates circular area with given `diameter`.
---@param diameter number
---@return number
function MathUtil.getCircularAreaD(diameter)
    return 0.25 * math.pi * diameter ^ 2
end

return MathUtil
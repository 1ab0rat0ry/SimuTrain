--- @class MathUtil
local MathUtil = {}

local INF = 1 / 0

--- Checks if the given value is NaN (not a number).
--- @param value number The number to test.
--- @return boolean True if `value` is NaN, false otherwise.
function MathUtil.isNaN(value)
    -- NaN is the only value that is not equal to itself
    return value ~= value
end

--- Checks if the given value is infinite (positive or negative).
--- @param value number The number to check.
--- @return boolean True if value is either positive or negative infinity, false otherwise.
function MathUtil.isInf(value)
    return value == INF or value == -INF
end

--- Clamps a number between a minimum and maximum value.
--- If the number is less than `min`, returns `min`; if greater than `max`, returns `max`.
--- Behavior is undefined if `min > max`.
--- @param value number The number to clamp.
--- @param min number Minimum value.
--- @param max number Maximum value.
--- @return number The clamped value.
function MathUtil.clamp(value, min, max)
    if value < min then return min
    elseif value > max then return max
    end

    return value
end

--- Clamps a number between 0 and 1.
--- @param value number The number to clamp.
--- @return number The clamped value between 0 and 1.
function MathUtil.clamp01(value)
    if value < 0 then return 0
    elseif value > 1 then return 1
    end

    return value
end

--- Performs a linear interpolation between `a` and `b` using a factor between 0 and 1.
--- The interpolation factor is constrained to the 0, 1 range.
--- @param factor number A value between 0 and 1.
--- @param a number Starting value.
--- @param b number Ending value.
--- @return number The interpolated value.
function MathUtil.lerp(factor, a, b)
    return a + (b - a) * MathUtil.clamp01(factor)
end

--- Performs a linear interpolation between `a` and `b`.
--- The interpolation is not constrained to the 0, 1 range.
--- @param factor number Interpolation factor.
--- @param a number Starting value.
--- @param b number Ending value.
--- @return number The interpolated value.
function MathUtil.lerpUnclamped(factor, a, b)
    return a + (b - a) * factor
end

--- Computes the inverse linear interpolation of a number within a given range.
--- This maps a number to a value between 0 and 1 based on its position between `a` and `b`.
--- @param value number The number to map.
--- @param a number Start of the input range.
--- @param b number End of the input range.
--- @return number The mapped value between 0 and 1.
function MathUtil.inverseLerp(value, a, b)
    if a == b then return 0 end

    return MathUtil.clamp01((value - a) / (b - a))
end

--- Maps a number from one range to another.
--- Given an input range `inStart`, `inEnd` and an output range `outStart`, `outEnd`,
--- this function returns the proportionally mapped value.
--- @param value number The input number.
--- @param inStart number Start of the input range.
--- @param inEnd number End of the input range.
--- @param outStart number Start of the output range.
--- @param outEnd number End of the output range.
--- @return number The number mapped to the output range.
function MathUtil.map(value, inStart, inEnd, outStart, outEnd)
    if inEnd == inStart then return outStart end

    return outStart + (outEnd - outStart) / (inEnd - inStart) * (value - inStart)
end

--- Changes the given number towards a target value without overshooting.
--- @param value number Current value.
--- @param target number The target number.
--- @param step number The maximum change of `value` performed in one call. Must be positive.
--- @return number The new value after change.
function MathUtil.towards(value, target, step)
    if step <= 0 then return value end
    if math.abs(target - value) <= step then return target end

    return value + MathUtil.sign(target - value) * step
end

--- Smoothly interpolates `value` based on the given `a` and `b`.
--- 1st-order derivative is equal to 0 at boundaries.
--- - source: [https://en.wikipedia.org/wiki/Smoothstep](https://en.wikipedia.org/wiki/Smoothstep)
--- @param value number The input number.
--- @param a number Start of the interpolation range.
--- @param b number The upper bound of the interpolation range.
--- @return number The interpolation result between 0 and 1.
function MathUtil.smoothstep(value, a, b)
    if a == b then return 0 end
    value = MathUtil.clamp01((value - a) / (b - a));

    return value * value * (3 - 2 * value);
end

--- Provides a smoother interpolation than smoothstep.
--- 1st- and 2nd-order derivatives are equal to 0 at boundaries.
--- - source: [https://en.wikipedia.org/wiki/Smoothstep#Variations](https://en.wikipedia.org/wiki/Smoothstep#Variations)
--- @param value number The input number.
--- @param a number Start of the interpolation range.
--- @param b number End of the interpolation range.
--- @return number The interpolation result between 0 and 1.
function MathUtil.smootherstep(value, a, b)
    if a == b then return 0 end
    value = MathUtil.clamp01((value - a) / (b - a));

    return value * value * value * (value * (6 * value - 15) + 10);
end

--- Gradually changes a value towards a target using critical damping.
--- Useful for smooth transitions without overshoot.
--- - source: Game Programming Gems 4, page 99
--- @param current number The current value.
--- @param target number The target value.
--- @param velocity number The current velocity.
--- @param smoothTime number The time over which to smooth. Determines how quickly the value approaches the target.
--- @param deltaTime number The time step.
--- @param maxSpeed number Maximum speed. Defaults to 1e10 if not provided.
--- @return number, number The updated value, and velocity.
--- @overload fun(current: number, target: number, velocity: number, smoothTime: number, deltaTime: number): number, number
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

--- Returns the sign of a number.
--- @param value number The number to evaluate.
--- @return number If negative -1, if zero 0, if positive 1.
function MathUtil.sign(value)
    return value > 0 and 1 or value < 0 and -1 or 0
end

--- Rounds a number to a given number of decimal places.
--- If places is omitted then number is rounded to the nearest integer.
--- Halfway cases are rounded towards larger number.
--- @param value number The number to round.
--- @param places number Optional. The number of decimal places.
--- @return number The rounded number.
--- @overload fun(value: number): number
function MathUtil.round(value, places)
    local factor = 10 ^ (places or 0)
    return math.floor(value * factor + 0.5) / factor
end

return MathUtil
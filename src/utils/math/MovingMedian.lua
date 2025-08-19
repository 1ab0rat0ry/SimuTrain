---@class MovingMedian
local MovingMedian = {
    sampleSize = 0,
    sampleIndex = 1,
    samples = {}
}
MovingMedian.__index = MovingMedian

function MovingMedian:new()
    ---@type MovingMedian
    local instance = {
        sampleSize = 0,
        sampleIndex = 1,
        samples = {}
    }

    return setmetatable(instance, self)
end

---Takes sample for calculating moving median.
---@param sample number
function MovingMedian:sample(sample)
    self.samples[self.sampleIndex] = sample
    self.sampleIndex = self.sampleIndex == self.sampleSize and 1 or self.sampleIndex + 1
end

---Calculates moving median from samples.
---@return number
function MovingMedian:get()
    local sortedSamples = {}
    local midIndex = math.ceil(self.sampleSize / 2)

    for i, _ in ipairs(self.samples) do
        sortedSamples[i] = self.samples[i]
    end
    table.sort(sortedSamples)

    if math.mod(midIndex, 2) == 0 then
        return (sortedSamples[midIndex] + sortedSamples[midIndex + 1]) / 2
    else
        return sortedSamples[midIndex + 1]
    end
end
--- @class Curve
--- @field points table<number, number>[]
--- @field length number
local Curve = {}
Curve.__index = Curve

--- @param points table<number, number>[]
--- @return Curve
function Curve:new(points)
    local instance = {
        points = points or {},
        length = table.getn(points or {})
    }

    return setmetatable(instance, self)
end

--- @param x number
--- @param y number
--function Curve:addPoint(x, y)
--    table.insert(self.points, {x, y})
--    table.sort(self.points, function(a, b) return a[1] < b[1] end)
--    self.length = self.length + 1
--end

--- @param x number
--- @return number
function Curve:getValue(x)
    if self.length == 0 then return 0 end
    if self.length == 1 then return self.points[1][2] end
    if x <= self.points[1][1] then return self.points[1][2] end
    if x >= self.points[self.length][1] then return self.points[self.length][2] end

    for i = 2, self.length do
        if self.points[i][1] > x then
            local prevPoint = self.points[i-1]
            local factor = (x - prevPoint[1]) / (self.points[i][1] - prevPoint[1])

            return prevPoint[2] + factor * (self.points[i][2] - prevPoint[2])
        end
    end

    return self.points[self.length][2]
end

return Curve
local LPM = {}

file_path = string.reverse(string.gsub(string.reverse(...), 'mpl', '', 1))
local Collider = require(file_path .. 'collider')
local SetFunctions = require(file_path .. 'utils')

local function New(_, xg, yg, sleep)
    local self = {
        world = love.physics.newWorld(xg, yg, sleep),
        colliders = {},
    }

    SetFunctions(self, self.world)

    return setmetatable(self, { __index = LPM })
end

function LPM:update(dt)
    self.world:update(dt)
end

function LPM:newRectangleCollider(x, y, width, height, body_type)
    local collider = Collider(self, "Rectangle", x, y, width, height, body_type)
    table.insert(self.colliders, collider)

    return collider
end

function LPM:newCircleCollider(x, y, r, body_type)
    local collider = Collider(self, "Circle", x, y, r, body_type)
    table.insert(self.colliders, collider)

    return collider
end

function LPM:newBSGRectangleCollider(x, y, width, height, corner_cut_size, body_type)
    local collider = Collider(self, "BSGRectangle", x, y, width, height, corner_cut_size, body_type)
    table.insert(self.colliders, collider)

    return collider
end

function LPM:removeCollider(collider)
    for i=#self.colliders, 1, -1 do
        if self.colliders[i] == collider then
            table.remove(self.colliders, i)
        end
    end
end

function LPM:draw()
    for _, collider in ipairs(self.colliders) do
        collider:draw()
    end
end

function LPM:release()
    self.world:destroy()
end

return setmetatable(LPM, { __call = New })
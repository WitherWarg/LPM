local LPM = {}

file_path = string.reverse(string.gsub(string.reverse(...), 'mpl', '', 1))
local Collider = require(file_path .. 'collider')
local SetFunctions = require(file_path .. 'set_functions')

local function New(_, xg, yg, sleep)
    local self = {
        world = love.physics.newWorld(xg, yg, sleep),
        colliders = {},
        classes = {},
        queries = {}
    }

    SetFunctions(self, self.world)

    setmetatable(self, { __index = LPM })

    self:createClasses{ name = 'Default' }

    return self
end

function LPM:update(dt)
    self.world:update(dt)
end

function LPM:draw()
    local color = {love.graphics.getColor()}

    for _, collider in ipairs(self.colliders) do
        love.graphics.setColor(unpack(self.classes['Default'].color))

        if not collider.classes then
            goto continue
        end

        for _, name in ipairs(collider.classes) do
            local class = self.classes[name]

            if class.color ~= self.classes['Default'].color and class.color ~= nil then
                love.graphics.setColor(unpack(class.color))
            end
        end

        ::continue::

        collider:draw()
    end

    love.graphics.setColor(unpack(color))

    for i=#self.queries, 1, -1 do
        if self.queries[i].type == "Line" then
            love.graphics.line(unpack(self.queries[i].arguments))
        end

        if self.queries[i].type == "Rectangle" then
            love.graphics.rectangle('line', unpack(self.queries[i].arguments))
        end

        table.remove(self.queries, i)
    end
end

function LPM:release()
    self.world:destroy()
end

--#region Collider Management
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
--#endregion

--#region Querying
function LPM:queryRectangleArea(x, y, width, height)
    local colliders = {}

    self.world:queryBoundingBox(x, y, x + width, y + height, function (fixture)
        table.insert(colliders, fixture:getUserData())

        return true
    end)

    table.insert(self.queries, { type = "Rectangle", arguments = { x, y, width, height } })

    return colliders
end

function LPM:queryLine(x1, y1, x2, y2)
    local colliders = {}

    self.world:rayCast(x1, y1, x2, y2, function (fixture)
        table.insert(colliders, fixture:getUserData())

        return 1
    end)

    table.insert(self.queries, { type = "Line", arguments = { x1, y1, x2, y2 } })

    return colliders
end
--#endregion

--#region Classes
function LPM:createClasses(...)
    local classes = {...}
    for _, class in ipairs(classes) do
       assert(class.name ~= nil, 'The format is "{ name = class_name }"')
 
       local last_category = 0
       for _, _ in pairs(self.classes) do
           last_category = last_category + 1
       end
 
       self.classes[class.name] = {
          category = last_category + 1,
          masks = class.masks or {},
          color = class.color or {1, 1, 1}
       }
    end
 
    for _, class in pairs(self.classes) do
       local masks = {}
       for _, other_class_name in ipairs(class.masks) do
          other_class = self.classes[other_class_name]
          assert(other_class ~= nil, string.format('Class "%s" does not exist.', other_class_name))
 
          table.insert(masks, other_class.category)
       end
 
       class.masks = masks
    end
end

function LPM:setClasses(collider, class_names)
    assert(type(class_names) == 'table', 'Class names are a table')
    assert(#class_names > 0, 'Must provide list of class_names.')
 
    local categories = {}
    local masks = {}
    
    for _, class_name in ipairs(class_names) do
       local class = self.classes[class_name]
       assert(class ~= nil, string.format('Class "%s" does not exist.', class_name))
 
       table.insert(categories, class.category)
 
       for _, mask in ipairs(class.masks) do
          table.insert(masks, mask)
       end
 
       collider:setCategory(unpack(categories))
       collider:setMask(unpack(masks))
    end

    collider.classes = class_names
end
--#endregion

return setmetatable(LPM, { __call = New })
local LPM = {}

file_path = string.reverse(string.gsub(string.reverse(...), 'mpl', '', 1))
local Collider = require(file_path .. 'collider')
local SetFunctions = require(file_path .. 'set_functions')

local function DrawQueries(self)
    for _, query in ipairs(self.queries) do
        if query.type == "Line" then
            local x1, y1, x2, y2 = unpack(query.arguments)
            love.graphics.line(x1, y1, x2, y2)
        end

        if query.type == "Rectangle" then
            local x, y, width, height = unpack(query.arguments)
            love.graphics.rectangle('line', x, y, width, height)
        end

        if query.type == "Circle" then
            local x, y, r = unpack(query.arguments)
            love.graphics.circle('line', x, y, r)
        end
    end
end

local function DrawCollider(classes, collider)
    local default_color = classes['Default'].color

    if not collider.classes then
        collider:draw()
    end

    for i, name in ipairs(collider.classes) do
        local class = classes[name]

        if class.color[1] ~= default_color[1] or class.color[2] ~= default_color[2] or class.color[3] ~= default_color[3] then
            love.graphics.setColor(unpack(class.color))
            break
        end

        if i == #collider.classes then
            love.graphics.setColor(unpack(default_color))
        end
    end

    collider:draw()
end

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
    -- Reset queries to be drawn
    self.queries = {}

    self.world:update(dt)
end

function LPM:draw()
    love.graphics.push('all')

    if self.can_draw_queries then
        DrawQueries(self)
    end

    for _, collider in ipairs(self.colliders) do
        DrawCollider(self.classes, collider)
    end

    love.graphics.pop()
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

function LPM:newLineCollider(x1, y1, x2, y2, body_type)
    local collider = Collider(self, "Line", x1, y1, x2, y2, body_type)
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
local function filter_query(lpm, colliders, class_names)
    if class_names == nil then
        return colliders
     end
  
     for i=#colliders, 1, -1 do
        local coll = colliders[i]
        local categories = {coll:getCategory()}
        local is_match = false
  
        for _, class_name in ipairs(class_names) do
           local class = lpm.classes[class_name]
           assert(class ~= nil, string.format('Class "%s" does not exist.', class_name))
  
           for _, category in ipairs(categories) do
              if class.category == category then
                 is_match = true
              end
           end
        end
  
        if not is_match then
           table.remove(colliders, i)
        end
     end
  
     return colliders
end

function LPM:queryRectangleArea(x, y, width, height, class_names)
    local colliders = {}

    self.world:queryBoundingBox(x, y, x + width, y + height, function (fixture)
        table.insert(colliders, fixture:getUserData())

        return true
    end)

    table.insert(self.queries, { type = "Rectangle", arguments = { x, y, width, height } })

    return filter_query(self, colliders, class_names)
end

function LPM:queryLine(x1, y1, x2, y2, class_names)
    local colliders = {}

    self.world:rayCast(x1, y1, x2, y2, function (fixture)
        table.insert(colliders, fixture:getUserData())

        return 1
    end)

    table.insert(self.queries, { type = "Line", arguments = { x1, y1, x2, y2 } })

    return filter_query(self, colliders, class_names)
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
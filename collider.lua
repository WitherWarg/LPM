local Collider = {}

local file_path = string.gsub(..., 'collider', '')
SetFunctions = require(file_path .. 'set_functions')

local function New(_, lpm, shape_type, ...)
    local self = {}

    if shape_type == "Rectangle" then
        local x, y, width, height, body_type = ...

        self.body = love.physics.newBody(lpm.world, x, y, body_type)
        self.shape = love.physics.newRectangleShape(width, height)

        function self:getWidth()
            return width
        end

        function self:getHeight()
            return height
        end

        function self:getDimensions()
            return self:getWidth(), self:getHeight()
        end
    elseif shape_type == "BSGRectangle" then
        local x, y, width, height, corner_cut_size, body_type = ...

        assert(corner_cut_size ~= nil, "Missing argument: corner_cut_size")

        self.body = love.physics.newBody(lpm.world, x, y, body_type)
        self.shape = love.physics.newPolygonShape(
            -width / 2, -height / 2 + corner_cut_size,
            -width / 2 + corner_cut_size, -height / 2,
            width / 2 - corner_cut_size, -height / 2,
            width / 2, -height / 2 + corner_cut_size,
            width / 2, height / 2 - corner_cut_size,
            width / 2 - corner_cut_size, height / 2,
            -width / 2 + corner_cut_size, height / 2,
            -width / 2, height / 2 - corner_cut_size
        )

        function self:getWidth()
            return width
        end

        function self:getHeight()
            return height
        end

        function self:getCornerCutSize()
            return corner_cut_size
        end

        function self:getDimensions()
            return self:getWidth(), self:getHeight()
        end
    elseif shape_type == "Circle" then
        local x, y, r, body_type = ...

        self.body = love.physics.newBody(lpm.world, x, y, body_type)
        self.shape = love.physics.newCircleShape(r)
    elseif shape_type == "Line" then
        local x1, y1, x2, y2, body_type = ...

        self.body = love.physics.newBody(lpm.world, 0, 0, body_type)
        self.shape = love.physics.newEdgeShape(x1, y1, x2, y2)
    end

    self.fixture = love.physics.newFixture(self.body, self.shape)
    self.fixture:setUserData(self)

    self.shape_type = shape_type

    self.lpm = lpm

    SetFunctions(self, self.body)
    SetFunctions(self, self.fixture)
    SetFunctions(self, self.shape)

    self:setFriction(0)
    self:setFixedRotation(true)
    self:setMass(1)

    return setmetatable(self, { __index = Collider })
end

function Collider:resize(...)
    local mass = self:getMass()
    local density = self:getDensity()
    local user_data = self.fixture:getUserData()
    local category = {self:getCategory()}
    local mask = {self:getMask()}

    self.shape:release()

    if self.shape_type == "Rectangle" then
        local width, height = ...

        self.shape:release()

        self.shape = love.physics.newRectangleShape(width, height)

        function self:getWidth()
            return width
        end

        function self:getHeight()
            return height
        end
    elseif self.shape_type == "BSGRectangle" then
        local width, height, corner_cut_size = ...
        corner_cut_size = corner_cut_size or self:getCornerCutSize()

        self.shape = love.physics.newPolygonShape(
            -width / 2, -height / 2 + corner_cut_size,
            -width / 2 + corner_cut_size, -height / 2,
            width / 2 - corner_cut_size, -height / 2,
            width / 2, -height / 2 + corner_cut_size,
            width / 2, height / 2 - corner_cut_size,
            width / 2 - corner_cut_size, height / 2,
            -width / 2 + corner_cut_size, height / 2,
            -width / 2, height / 2 - corner_cut_size
        )

        function self:getWidth()
            return width
        end

        function self:getHeight()
            return height
        end
    elseif self.shape_type == "Circle" then
        local r = ...

        self.shape = love.physics.newCircleShape(r)
    elseif self.shape_type == "Line" then
        local x1, y1, x2, y2 = ...

        self.shape = love.physics.newEdgeShape(x1, y1, x2, y2)
    end
 
    self.fixture:destroy()
 
    self.fixture = love.physics.newFixture(self.body, self.shape, density)
    self.fixture:setUserData(user_data)
 
    SetFunctions(self, self.fixture)
    SetFunctions(self, self.shape)
 
    self:setMass(mass)
    self:setCategory(unpack(category))
    self:setMask(unpack(mask))
end

function Collider:draw()
    local shape_type = self:getType()

    if shape_type == "circle" then
        love.graphics.circle('line', self:getX(), self:getY(), self:getRadius())
    elseif shape_type == "polygon" then
        love.graphics.polygon('line', self:getWorldPoints(self:getPoints()))
    elseif shape_type == "edge" then
        love.graphics.line(self:getWorldPoints(self:getPoints()))
    end
end

function Collider:destroy()
    self.fixture:setUserData(nil)
    self.fixture:destroy()
    self.body:destroy()

    self.lpm:removeCollider(self)
end

return setmetatable(Collider, { __call = New })
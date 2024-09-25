local font = love.graphics.newFont(30)
local margin = 20

function debug(...)
    local count = select('#', ...)
    
    if count == 0 then
        return
    end

    local values = {}
    local longest = ''
    local ouput = '%s'

    for i = 1, count do
        local value = tostring(select(i, ...))

        if value == '' then
            value = 'empty_string'
        end
        
        values[i] = value

        if string.len(longest) < string.len(value) then
            longest = values[i]
        end

        if i > 1 then
            ouput = ouput .. '\n%s'
        end
    end

    love.graphics.push('all')
        love.graphics.setFont(font)

        local width, height = font:getWidth(longest), font:getHeight() * count

        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 10, 10, width + margin, height + margin)

        love.graphics.setColor(1, 1, 1)
        love.graphics.print( string.format( ouput, unpack(values) ), margin, margin )
    love.graphics.pop()
end
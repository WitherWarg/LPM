function love.load()
    require('utils.debug')
    require('utils.table')

    LPM = require('lpm')

    LPM = LPM(0, 2000)
end

function love.update(dt)
    LPM:update(dt)
end

function love.draw()
    LPM:draw()
end
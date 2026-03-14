sw, sh = love.graphics.getDimensions()

DEBUG = false

IS_MOBILE = love.system.getOS() == 'Android' or love.system.getOS() == 'iOS'
IS_WEB = love.system.getOS() == 'Web'
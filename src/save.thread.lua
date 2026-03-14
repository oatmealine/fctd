local filename, data = ...

if love.filesystem.getInfo(filename, 'file') then
  local old = love.filesystem.read(filename)
  love.filesystem.write(filename .. '.bak', old)
end
love.filesystem.write(filename, data)
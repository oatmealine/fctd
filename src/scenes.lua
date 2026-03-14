scenes = {}

---@type Scene[]
scenes.stack = {}

scenes.scene = {
  game = require 'src.scene.game',
}

scenes.callbacks = {}
for _, s in ipairs({'draw', 'update', 'resize', 'keypressed', 'mousepressed', 'mousereleased', 'mousemoved', 'wheelmoved'}) do
  scenes.callbacks[s] = function(...)
    for _, scene in ipairs(scenes.stack) do
      if scene.callbacks[s] then
        scene.callbacks[s](...)
      end
    end
  end
end

function scenes.setScene(scene)
  scenes.stack = { scene }
end
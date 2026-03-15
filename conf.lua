function love.conf(t)
  t.identity = 'oatmealine.fctd'
  t.appendidentity = true
  t.version = '11.3'

  t.window.title = 'fctd'
  t.window.icon = nil
  t.window.width = 1200
  t.window.height = 800
  t.window.resizable = false
  t.window.minwidth = 600
  t.window.minheight = 400
  t.window.depth = 16

  t.modules.audio = true
  t.modules.data = true
  t.modules.event = true
  t.modules.font = true
  t.modules.graphics = true
  t.modules.image = true
  t.modules.joystick = true
  t.modules.keyboard = true
  t.modules.math = true
  t.modules.mouse = true
  t.modules.physics = false
  t.modules.sound = true
  t.modules.system = true
  t.modules.thread = true
  t.modules.timer = true
  t.modules.touch = false
  t.modules.video = false
  t.modules.window = true
end
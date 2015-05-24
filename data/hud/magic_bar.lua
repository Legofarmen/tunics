-- The magic bar shown in the game screen.

local magic_bar = {}

function magic_bar:new(game)

  local object = {}
  setmetatable(object, self)
  self.__index = self

  object:initialize(game)

  return object
end

function magic_bar:initialize(game)

  self.game = game
  self.surface = sol.surface.create(16, 40)
  self.surface2 = sol.surface.create(16,40)
  self.magic_bar_img = sol.surface.create("hud/magic_bar.png")
  self.container_sprite = sol.sprite.create("hud/magic_bar")
  self.magic_displayed = game:get_magic()
  --zentropy.debug(game:get_magic())
  self.max_magic_displayed = 0

  self:check()
  self:rebuild_surface()
end

-- Checks whether the view displays the correct info
-- and updates it if necessary.
function magic_bar:check()

  local need_rebuild = false
  local max_magic = self.game:get_max_magic()
  local magic = self.game:get_magic()

  -- Maximum magic.
  if max_magic ~= self.max_magic_displayed then
    need_rebuild = true
    if self.magic_displayed > max_magic then
      self.magic_displayed = max_magic
    end
    self.max_magic_displayed = max_magic
    if max_magic > 0 then
      self.container_sprite:set_direction(0)
    end
  end

  -- Current magic.
  if magic ~= self.magic_displayed then
    need_rebuild = true
    local increment
    if magic < self.magic_displayed then
      increment = -1
    elseif magic > self.magic_displayed then
      increment = 1
    end
    if increment ~= 0 then
      self.magic_displayed = self.magic_displayed + increment

      -- Play the magic bar sound.
      if (magic - self.magic_displayed) % 10 == 1 then
	sol.audio.play_sound("magic_bar")
      end
    end
  end

  -- Redraw the surface only if something has changed.
  if need_rebuild then
    self:rebuild_surface()
  end

  -- Schedule the next check.
  sol.timer.start(self.game, 20, function()
    self:check()
  end)
end

function magic_bar:rebuild_surface()

	self.surface:clear()
	self.surface2:clear()

  -- Max magic.
  self.container_sprite:draw(self.surface)

  -- Current magic.
  self.magic_bar_img:draw_region(16, -31 + self.magic_displayed, 16, 34, self.surface2)
end
 
function magic_bar:set_dst_position(x, y)
  self.dst_x = x
  self.dst_y = y
end

function magic_bar:on_draw(dst_surface)
	local opacity = 64
	if self.max_magic_displayed > 0 then
		opacity = 255
	end
	self.surface:set_opacity(opacity)
    local x, y = self.dst_x, self.dst_y
    local width, height = dst_surface:get_size()
    if x < 0 then
      x = width + x
    end
    if y < 0 then
      y = height + y
    end
	
    self.surface:draw(dst_surface, x, y)
	self.surface2:draw(dst_surface, x, y+3)
end

return magic_bar


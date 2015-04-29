-- The small keys counter shown during dungeons or maps with small keys enabled.

local amounts = {}

function amounts:new(game)

  local object = {}
  setmetatable(object, self)
  self.__index = self

  object:initialize(game)

  return object
end

function amounts:initialize(game)

	self.game = game
	self.visible = false
	self.surface = sol.surface.create(57, 21)
	self.icon_img = sol.surface.create("hud/amounts.png")
	self.keys_digits_text = sol.text_surface.create{
		font = "white_digits",
		horizontal_alignment = "left",
		vertical_alignment = "top",
	}
	self.bombs_digits_text = sol.text_surface.create{
		font = "white_digits",
		horizontal_alignment = "left",
		vertical_alignment = "top",
	}
	self.arrows_digits_text = sol.text_surface.create{
		font = "white_digits",
		horizontal_alignment = "left",
		vertical_alignment = "top",
	}

  self:check()
  self:rebuild_surface()
end

function amounts:check()

	local need_rebuild = false

	-- Check the amount of bombs
	local nb_bombs = self.game:get_value('bomb_amount')
	if not nb_bombs then
		nb_bombs = "0"
	end
	if string.len(nb_bombs) < 2 then
		nb_bombs = "0" .. nb_bombs
	end
	local nb_bombs_displayed = tonumber(self.bombs_digits_text:get_text())
	if nb_bombs_displayed ~= nb_bombs then
		self.bombs_digits_text:set_text(nb_bombs)
		need_rebuild = true
	end

	-- Check the amount of arrows
	local nb_arrows = self.game:get_value('bow_amount')
	if not nb_arrows then
		nb_arrows = "0"
	end
	if string.len(nb_arrows) < 2 then
		nb_arrows = "0" .. nb_arrows
	end
	local nb_arrows_displayed = tonumber(self.arrows_digits_text:get_text())
	if nb_arrows_displayed ~= nb_arrows then
		self.arrows_digits_text:set_text(nb_arrows)
		need_rebuild = true
	end

	-- Check the number of small keys.
	local nb_keys = self.game:get_value('small_key_amount')
	local nb_keys_displayed = tonumber(self.keys_digits_text:get_text())
	if nb_keys_displayed ~= nb_keys then
		self.keys_digits_text:set_text(nb_keys)
		need_rebuild = true
	end    

	if not self.visible then
		self.visible = true
		need_rebuild = true
	end

	-- Redraw the surface is something has changed.
	if need_rebuild then
		self:rebuild_surface()
	end

	-- Schedule the next check.
	sol.timer.start(self.game, 40, function()
		self:check()
	end)
end

function amounts:rebuild_surface()

	self.surface:clear()
	self.icon_img:draw(self.surface)
	self.bombs_digits_text:draw(self.surface, 1, 9)
	self.arrows_digits_text:draw(self.surface, 25, 9)
	self.keys_digits_text:draw(self.surface, 47, 9)
end

function amounts:set_dst_position(x, y)
  self.dst_x = x
  self.dst_y = y
end

function amounts:on_draw(dst_surface)

  if self.visible then
    local x, y = self.dst_x, self.dst_y
    local width, height = dst_surface:get_size()
    if x < 0 then
      x = width + x
    end
    if y < 0 then
      y = height + y
    end

    self.surface:draw(dst_surface, x, y)
  end
end

return amounts


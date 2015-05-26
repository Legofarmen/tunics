local title_screen = {}

function title_screen:on_started()
	self.surface = sol.surface.create(320, 240)
	sol.timer.start(self, 300, function()
		self:title()
	end)
end

function title_screen:title()

	self.phase = "title"

	self.background_img = sol.surface.create("menus/title_bg.png")
	self.bg_img = sol.surface.create("menus/title_bg.png")
	self.logo_img = sol.surface.create("menus/title_logo.png")
	self.borders_img = sol.surface.create("menus/title_borders.png")

	self.press_space_img = sol.text_surface.create{
		color = {255, 255, 255},
		text_key = "title_screen.press_space",
		horizontal_alignment = "center"
	}

	self.show_press_space = false
	function switch_press_space()
		self.show_press_space = not self.show_press_space
		sol.timer.start(self, 500, switch_press_space)
	end
	sol.timer.start(self, 6500, switch_press_space)
	
	self.show_logo = false
	function switch_logo()
		self.show_logo = not self.show_logo
	end
	sol.timer.start(self, 3000, switch_logo)
	
	self.bg_xy = {x = 0, y = 0}
	function move_bg()
		self.bg_xy.y = self.bg_xy.y + 1
		if self.bg_xy.y > 480 then
			self.bg_xy.y = self.bg_xy.y - 481
		end
		sol.timer.start(self, 50, move_bg)
	end
	sol.timer.start(self, 50, move_bg)

	self.surface:fade_in(50)

	self.allow_skip = false
	sol.timer.start(self, 2000, function()
		self.allow_skip = true
	end)
end

function title_screen:on_draw(dst_surface)
	if self.phase == "title" then
		self:draw_phase_title(dst_surface)
	end
	local width, height = dst_surface:get_size()
	self.surface:draw(dst_surface, width / 2 - 160, height / 2 - 120)
end

function title_screen:draw_phase_title()
	self.surface:fill_color({0, 0, 0})
	self.background_img:draw(self.surface)
  
	local x, y = self.bg_xy.x, self.bg_xy.y
	self.bg_img:draw(self.surface, x, y)
	x = self.bg_xy.x - 320
	self.bg_img:draw(self.surface, x, y)
	x = self.bg_xy.x
	y = self.bg_xy.y - 480
	self.bg_img:draw(self.surface, x, y)
	x = self.bg_xy.x - 320
	y = self.bg_xy.y - 480
	self.bg_img:draw(self.surface, x, y)

	self.borders_img:draw(self.surface, 0, 0)
	
	if self.show_press_space then
		self.press_space_img:draw(self.surface, 160, 200)
	end
	
	if self.show_logo then
		self.logo_img:draw(self.surface)
	end
end

function title_screen:on_command_pressed(command)
	return self:try_finish_title()
	
end

function title_screen:try_finish_title()
	local handled = false
	if self.phase == "title" and self.allow_skip and not self.finished then
		self.finished = true

		self.surface:fade_out(30)
		sol.timer.start(self, 700, function()
			self:finish_title()
		end)
		handled = true
	end
	return handled
end

function title_screen:finish_title()
	sol.menu.stop(self)
end

return title_screen

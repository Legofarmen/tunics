

local legofarmen_logo = {}

function legofarmen_logo:on_started()

  -- black screen during 0.3 seconds
	self.phase = "black"
	
	self.surface = sol.surface.create(320, 240)
	sol.timer.start(self, 300, function()
		self:show_logo()
		sol.audio.play_music("title_screen")
		sol.timer.start(20000, function()
			sol.audio.play_music("great_fairy")
		end)
		
	end)
	
	-- use these 0.3 seconds to preload all sound effects
	sol.audio.preload_sounds()
end

function legofarmen_logo:show_logo()
	
	-- "Legofarmen presents" displayed for two seconds
	self.phase = "lego_presents"
	self.lego_presents_img = 
		sol.surface.create("legofarmen_logo.png", true)

	local width, height = self.lego_presents_img:get_size()
	self.lego_presents_pos = { 160 - width / 2, 120 - height / 2 }
	
	sol.timer.start(self, 2000, function()
		self.surface:fade_out(10)
		sol.timer.start(self, 700, function()
			self:finish()
		end)
	end)
end

function legofarmen_logo:on_draw(dst_surface)

  if self.phase == "lego_presents" then
    self.lego_presents_img:draw(self.surface, self.lego_presents_pos[1], self.lego_presents_pos[2])
  end
  local width, height = dst_surface:get_size()
  self.surface:draw(dst_surface, width / 2 - 160, height / 2 - 120)

end

function legofarmen_logo:finish()
	sol.menu.stop(self)
end

return legofarmen_logo
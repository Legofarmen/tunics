local color = require 'lib/color'

local legofarmen_logo = {}

function legofarmen_logo:on_started()

    -- black screen during 0.3 seconds
	self.phase = "black"
	self.surface = sol.surface.create(320, 240)
	self.timer = sol.timer.start(self, 300, function()
		self:show_logo()
	end)
	
	-- use these 0.3 seconds to preload all sound effects
	sol.audio.preload_sounds()
end

function legofarmen_logo:show_logo()

	-- "Legofarmen presents" displayed for two seconds
	self.phase = "show_logo"
	self.lego_presents_img = sol.surface.create("legofarmen_logo.png", true)

	local width, height = self.lego_presents_img:get_size()
	self.lego_presents_pos = { 160 - width / 2, 120 - height / 2 }

    math.randomseed(os.time())
    local r, g, b = color.hslToRgb(math.random(), 179/255, 114/255, 1)
	self.background_img = sol.surface.create(width, height)
    self.background_img:fill_color({r, g, b})
	
	self.timer = sol.timer.start(self, 2000, function()
        self:fade_out()
	end)

    sol.audio.play_music("title_screen")
end

function legofarmen_logo:fade_out()

	self.phase = "fade_out"
    self.surface:fade_out(10)
    self.timer = sol.timer.start(self, 700, function()
        self:finish()
    end)
end

function legofarmen_logo:on_draw(dst_surface)

    if self.phase == "show_logo" then
        self.background_img:draw(self.surface, self.lego_presents_pos[1], self.lego_presents_pos[2])
        self.lego_presents_img:draw(self.surface, self.lego_presents_pos[1], self.lego_presents_pos[2])
    end
    local width, height = dst_surface:get_size()
    self.surface:draw(dst_surface, width / 2 - 160, height / 2 - 120)
end

function legofarmen_logo:finish()
	sol.menu.stop(self)
end

function legofarmen_logo:on_command_pressed(command)
    if self.phase == 'show_logo' then
        self.timer:stop()
        self:fade_out()
        return true
    end
end

return legofarmen_logo

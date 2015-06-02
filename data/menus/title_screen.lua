local title_screen = {}

local max_tunics = 500

function title_screen:on_started()
	self.surface = sol.surface.create(320, 240)
	sol.timer.start(self, 300, function()
		self:title()
	end)
end

function title_screen:title()

	self.phase = "title"

	self.logo_img = sol.surface.create("menus/title_logo.png")
	self.borders_img = sol.surface.create("menus/title_borders.png")

    local angle = math.pi + math.atan(2)
    local tunic_w, tunic_h = 16, 16
    local tunic_x, tunic_y = 8, 13
    local max_dist = (240 + tunic_h) / -math.sin(angle)
    local max_x = 320 + max_dist * -math.cos(angle)
    local start_y = tunic_y - tunic_h
    local counter = 1

    function start_movement(sprite, callback)
        local m = sol.movement.create('straight')
        m:set_speed(100)
        m:set_angle(angle)
        m:set_max_distance(max_dist)
        m.on_finished = callback
        local a = 1 / counter
        local b = a * 0.5 + (1 - a) * math.random()
        sprite:set_xy(b * max_x, start_y)
        m:start(sprite)
        counter = counter + 1
    end

    self.tunics = {}

    function add_tunic(repeating)
        local tunic = sol.sprite.create('entities/items')
        tunic:set_animation('tunic')
        table.insert(self.tunics, tunic)
        if repeating then
            local function restart()
                start_movement(tunic, restart)
            end
            restart()
        else
            start_movement(tunic, function ()
                for i, t in ipairs(self.tunics) do
                    if tunic == t then
                        table.remove(self.tunics, i)
                        break
                    end
                end
            end)
        end
    end

    function trickle_tunics(counter, delay, repeating, callback)
        if counter > 0 then
            add_tunic(repeating)
            sol.timer.start(delay, function ()
                trickle_tunics(counter - 1, delay, repeating, callback)
            end)
        elseif callback then
            callback()
        end
    end

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


	
	self.surface:fade_in(50, function()
        local musics = {
            {
                id = 'fortune_teller',
                first_delay = 1550,
                delay = 1550,
                speed_up_time = 9400,
            },
            {
                id = 'mini_game',
                first_delay = 1800,
                delay = 1280,
                speed_up_time = 12000,
            },
        }
        local music = musics[math.random(#musics)]

        sol.audio.play_music(music.id)

        sol.timer.start(self, 6500, switch_press_space)

        local border_delay = 400

        local speed_up_count = music.speed_up_time / music.delay - 2

        sol.timer.start(music.first_delay - border_delay, function ()
            trickle_tunics(speed_up_count, music.delay, false, function ()
                trickle_tunics(max_tunics, music.delay / 12, true)
            end)
        end)
    end)

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
    for i, tunic in ipairs(self.tunics) do
        tunic:draw(self.surface)
    end

	self.borders_img:draw(self.surface, 0, 0)
	
	if self.show_press_space then
		self.press_space_img:draw(self.surface, 160, 160)
	end
	
    self.logo_img:draw(self.surface)
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

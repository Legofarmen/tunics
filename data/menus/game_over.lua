local game_over_menu = {}  -- The game-over menu.

local music
local hero_was_visible
local hero_dead_sprite
local hero_dead_x, hero_dead_y
local fade_sprite
local fairy_sprite
local cursor_position
local state

function game_over_menu:on_started()
	local game = zentropy.game.game
	local hero = game:get_hero()
  
	game:set_hud_enabled(false)
	game:set_pause_allowed(false)
  
  hero_was_visible = hero:is_visible()
  hero:set_visible(false)
  music = sol.audio.get_music()
  fade_sprite = sol.sprite.create("hud/gameover_fade")
  local tunic = game:get_ability("tunic")
  hero_dead_sprite = sol.sprite.create("hero/tunic" .. tunic)
  hero_dead_sprite:set_animation("hurt")
  hero_dead_sprite:set_direction(hero:get_direction())
  hero_dead_sprite:set_paused(true)
  
  fairy_sprite = sol.sprite.create("entities/items")
  fairy_sprite:set_animation("fairy")
  state = "waiting_start"

  local map = game:get_map()
  local camera_x, camera_y = map:get_camera_position()
  local hero_x, hero_y = hero:get_position()
  hero_dead_x = hero_x - camera_x
  hero_dead_y = hero_y - camera_y

  sol.timer.start(self, 500, function()
    state = "closing_game"
    sol.audio.stop_music()
    fade_sprite:set_animation("close")
    fade_sprite.on_animation_finished = function()
      if state == "closing_game" then
        state = "red_screen"
        sol.audio.play_sound("hero_dying")
        hero_dead_sprite:set_paused(false)
        hero_dead_sprite:set_direction(0)
        hero_dead_sprite:set_animation("dying")
		hero_dead_sprite.on_animation_finished = function()
			hero_dead_sprite:set_animation("dead") 
		end
		
        sol.timer.start(self, 2000, function()
          
			game:get_hero():teleport('rooms/game_over')
					  
        end)
      end
    end
  end)
end

function game_over_menu:on_finished()
local game = zentropy.game.game
  local hero = game:get_hero()
  if hero ~= nil then
    hero:set_visible(hero_was_visible)
  end
  music = nil
  hero_dead_sprite = nil
  fade_sprite = nil
  fairy_sprite = nil
  cursor_position = nil
  state = nil
  sol.timer.stop_all(self)
end

local black = {0, 0, 0}
local red = {224, 32, 32}

function game_over_menu:on_draw(dst_surface)

  if state ~= "waiting_start" and state ~= "closing_game" then
    -- Hide the whole map.
    dst_surface:fill_color(black)
  end

  if state == "closing_game"
      or state == "opening_menu" then
    fade_sprite:draw(dst_surface, hero_dead_x, hero_dead_y)
  elseif state == "red_screen" then
    dst_surface:fill_color(red)
  end

 
  if state ~= "resume_game" then
    hero_dead_sprite:draw(dst_surface, hero_dead_x, hero_dead_y)
    if state == "saved_by_fairy" then
      fairy_sprite:draw(dst_surface)
    end
  end
end

return game_over_menu
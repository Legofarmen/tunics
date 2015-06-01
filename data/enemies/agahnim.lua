local enemy = ...

local zentropy = require "lib/zentropy"

-- Agahnim (Boss of dungeon 5)

local nb_sons_created = 0
local initial_life = 1 * zentropy.game.game:get_value('tier')

local treasure, treasure_count
if zentropy.game.game:get_value('tier') >= 18 then
    treasure, treasure_count = "fairy", 3
else
    treasure, treasure_count = "heart_container", 1
end

local blue_fireball_high_health_proba, blue_fireball_low_health_proba
if zentropy.game.game:get_value('tier') >= 4 then
    blue_fireball_high_health_proba, blue_fireball_low_health_proba = 0.33, 0.5
else
    blue_fireball_high_health_proba, blue_fireball_low_health_proba = 0, 0
end

local low_health_fireball_count
if zentropy.game.game:get_value('tier') >= 6 then
    low_health_fireball_count = 1
elseif zentropy.game.game:get_value('tier') >= 3 then
    low_health_fireball_count = 2
else
    low_health_fireball_count = 3
end

local fireball_bounces
if zentropy.game.game:get_value('tier') >= 5 then
    fireball_bounces = 3
elseif zentropy.game.game:get_value('tier') >= 3 then
    fireball_bounces = 2
elseif zentropy.game.game:get_value('tier') >= 2 then
    fireball_bounces = 1
else
    fireball_bounces = 0
end

local finished = false
local vulnerable = false
local sprite

function enemy:on_created()
	self.positions = {}
	self:set_life(initial_life)
	self:set_damage(6)
	self:set_optimization_distance(0)
	self:set_size(16, 16)
	self:set_origin(8, 13)
	self:set_invincible()
	self:set_attack_consequence("sword", "custom")
	self:set_attack_consequence("arrow", "ignored")
	self:set_attack_consequence("hookshot", "protected")
	self:set_attack_consequence("boomerang", "protected")
	self:set_pushed_back_when_hurt(false)
	self:set_push_hero_on_sword(true)
	sprite = self:create_sprite("enemies/agahnim")
end

function enemy:on_custom_attack_received()
    self:get_map():get_entity("hero"):start_electrocution(500, self:get_damage())
end

function enemy:on_restarted()
    vulnerable = false

    if not finished then
        sprite:set_animation("stopped")
        sol.timer.start(self, 100, function()
            sprite:fade_out(function() self:hide() end)
        end)
    else
        sprite:set_animation("hurt")
        self:get_map():get_entity("hero"):freeze()
		sol.audio.play_sound('boss_killed')
        sol.timer.start(self, 500, function() self:end_dialog() end)
        sol.timer.start(self, 1000, function() sprite:fade_out() end)
        sol.timer.start(self, 1500, function() 
			self:escape() 
			sol.audio.play_sound('secret')
		end)
    end
end

function enemy:hide()
  vulnerable = false
  self:set_position(-100, -100)
  sol.timer.start(self, 500, function() self:unhide() end)
end

function enemy:unhide()
	local position = (self.positions[math.random(#self.positions)])
  self:set_position(position.x + 24, position.y + 32)
  sprite:set_animation("walking")
  sprite:set_direction(position.direction4)
  sprite:fade_in()
  sol.timer.start(self, 1000, function() self:fire_step_1() end)
end

function enemy:fire_step_1()

  sprite:set_animation("arms_up")
  sol.timer.start(self, 1000, function() self:fire_step_2() end)
end

function enemy:fire_step_2()

    local proba = self:has_low_health() and blue_fireball_high_health_proba or blue_fireball_low_health_proba
    if math.random() <= proba then
        sprite:set_animation("preparing_blue_fireball")
    else
        sprite:set_animation("preparing_red_fireball")
    end
    sol.audio.play_sound("boss_charge")
    sol.timer.start(self, 1500, function() self:fire_step_3() end)
end

function enemy:fire_step_3()

    local sound, breed
    if sprite:get_animation() == "preparing_blue_fireball" then
        sound = "cane"
        breed = "fireball_triple_blue"
    else
        sound = "boss_fireball"
        breed = "fireball_triple_red"
    end
    sprite:set_animation("stopped")
    sol.audio.play_sound(sound)

    vulnerable = true
    sol.timer.start(self, 1300, function() self:restart() end)

    local function throw_fire()
        nb_sons_created = nb_sons_created + 1
        local fireball = self:create_enemy{
            name = "agahnim_fireball_" .. nb_sons_created,
            breed = breed,
            x = 0,
            y = -21
        }
        fireball.max_bounces = fireball_bounces
    end

    local function trickle(count, delay, callback)
        if count <= 0 then return end
        callback()
        sol.timer.start(self, delay, function() trickle(count - 1, delay, callback) end)
    end

    local count = self:has_low_health() and 3 or 1
    trickle(count, 200, throw_fire)
end

function enemy:has_low_health()
    return self:get_life() <= initial_life / 2
end

function enemy:receive_bounced_fireball(fireball)

  if fireball:get_name():find("^agahnim_fireball")
      and vulnerable then
    -- Receive a fireball shot back by the hero: get hurt.
    sol.timer.stop_all(self)
    fireball:remove()
    self:hurt(1)
  end
end

function enemy:on_hurt(attack)

  local life = self:get_life()
  if life <= 0 then
    self:get_map():remove_entities("agahnim_fireball")
    self:set_life(1)
    finished = true
  end
end

function enemy:end_dialog()

  self:get_map():remove_entities("agahnim_fireball")
  sprite:set_ignore_suspend(true)
  --self:get_map():get_game():start_dialog("dungeon_5.agahnim_end")
  
end

function enemy:escape()

    local x, y = self:get_position()
    for i = 1, treasure_count do
        self:get_map():create_pickable{
            treasure_name = treasure,
            treasure_variant = 1,
            x = x,
            y = y,
            layer = 1
        }
    end
    self:get_map():get_entity("hero"):unfreeze()
    --self:get_map():get_game():set_value("b520", true)
    if self.on_escape then
        self:on_escape()
    end
    self:remove()
end

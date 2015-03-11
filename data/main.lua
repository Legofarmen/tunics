sol.main.load_file('loadmap.lua')

function sol.main:on_started()
  sol.language.set_language("en")

  local exists = sol.game.exists("zentropy1.dat")
  local game = sol.game.load("zentropy1.dat")
  if not exists then
    game:set_max_life(12)
    game:set_life(game:get_max_life())
  end

  require('lib/map_include.lua')

  game:set_starting_location('dungeons/dungeon1')

  function game:on_command_pressed(command)
      if command == 'pause' and game:is_paused() then
          game:save()
          print("saved")
      end
  end

  game:start()
end

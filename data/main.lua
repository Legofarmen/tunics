local zentropy = require 'lib/zentropy'
local util = require 'lib/util'

zentropy.init()

util.wdebug_truncate()

function sol.main:on_started()
    sol.language.set_language("en")
    math.randomseed(os.time())

    local game = zentropy.game.new_game('zentropy1.dat')
    zentropy.game.next_tier()
    game:start()
end

local map, data = ...

map:add_on_started(function ()
    if chest:is_open() then
        switch:set_activated(true)
    else
        chest:set_enabled(false)
    end
end)

function switch:on_activated()
    chest:set_enabled(true)
end

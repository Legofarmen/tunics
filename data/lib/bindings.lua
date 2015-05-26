local bindings = {}

local commands = {
    escape =    { buttons={6}, keys={'escape'} },
    map =       { buttons={2}, keys={'tab'} },
    inventory = { buttons={3}, keys={'w'} },
    attack =    { buttons={0}, keys={'s'} },
    item_1 =    { buttons={4}, keys={'a'} },
    item_2 =    { buttons={5}, keys={'d'} },
    action =    { buttons={1}, keys={'space', 'return', 'kp return'} },
    up =        { keys={'up'} },
    down =      { keys={'down'} },
    left =      { keys={'left'} },
    right =     { keys={'right'} },
}

local axis_commands = {
    [0] = {
        [-1] = 'left',
        [1] = 'right',
    },
    [1] = {
        [-1] = 'up',
        [1] = 'down',
    },
}

function bindings.mixin(o)
    local keys = {}
    local buttons = {}
    for command, bindings in pairs(commands) do
        for _, key in ipairs(bindings.keys) do
            keys[key] = command
        end
        for _, button in ipairs(bindings.buttons or {}) do
            buttons[button] = command
        end
    end
    local axis_state = {}

    local function press(command)
        if o.on_command_pressed then
            return o:on_command_pressed(command)
        else
            return false
        end
    end

    local function release(command)
        if o.on_command_released then
            return o:on_command_released(command)
        else
            return false
        end
    end

    function o:on_key_pressed(key, modifiers)
        if keys[key] and not modifiers.alt and not modifiers.control then
            return press(keys[key])
        elseif key == "f5" then
            -- F5: change the video mode.
            sol.video.switch_mode()
        elseif (key == "return" and (modifiers.alt or modifiers.control)) or key == "f11" then
            -- Alt + Return or Ctrl + Return or F11: switch fullscreen.
            sol.video.set_fullscreen(not sol.video.is_fullscreen())
        elseif key == "f4" and modifiers.alt then
            -- Alt + F4: stop the program.
            sol.main.exit()
        end
        return true
    end

    function o:on_key_released(key, modifiers)
        if keys[key] then
            return release(keys[key])
        else
            return true
        end
    end

    function o:on_joypad_button_pressed(button, modifiers)
        if buttons[button] then
            return press(buttons[button])
        end
    end

    function o:on_joypad_button_released(button, modifiers)
        if buttons[button] then
            return release(buttons[button])
        end
    end

    function o:on_joypad_axis_moved(axis, state)
        local old_state = axis_state[axis] or 0
        axis_state[axis] = state
        if state ~= 0 then
            release(axis_commands[axis][old_state])
            return press(axis_commands[axis][state])
        elseif old_state ~= 0 then
            release(axis_commands[axis][old_state])
        end
    end

end

return bindings

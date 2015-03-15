local Class = require 'lib/class'
local Util = require 'lib/util'


local Layout = {}


local WeightVisitor = {}
setmetatable(WeightVisitor, WeightVisitor)

function WeightVisitor:visit_room(room)
    local weights = {
        Room=0,
        Treasure=0,
        Enemy=0,
    }
    room:each_child(function (key, child)
        weights[child.class] = weights[child.class] + child:accept(self)
    end)
    return math.max(1, weights.Room)
end

function WeightVisitor:visit_treasure(treasure)
    return 0
end

function WeightVisitor:visit_enemy(enemy)
    return 0
end


function add_doorway(separators, x, y, direction, savegame_variable)
    separators[y] = separators[y] or {}
    separators[y][x] = separators[y][x] or {}
    separators[y][x][Layout.DIRECTIONS[direction]] = savegame_variable
end


Layout.DIRECTIONS = { east=0, north=1, west=2, south=3, }


local BaseVisitor = Class:new()

function BaseVisitor:visit_enemy(enemy)
    table.insert(self.enemies, enemy)
end

function BaseVisitor:visit_treasure(treasure)
    table.insert(self.items, treasure)
end

function BaseVisitor:visit_room(room)
    local y = self.y
    local x0 = self.x
    local is_eastward = self.is_eastward
    local x1 = x0
    local doors = {}
    local items = {}
    local enemies = {}

    if self.doors then
        if is_eastward then
            self.doors.east = Util.filter_keys(room, {'see','reach','open'})
        else
            self.doors.north = Util.filter_keys(room, {'see','reach','open'})
        end
    end

    local total_weight = 0
    local heavy_weight = 0
    local heavy_key = nil
    room:each_child(function (key, child)
        local child_weight = child:accept(WeightVisitor)
        total_weight = total_weight + child_weight
        if child_weight > heavy_weight then
            heavy_weight = child_weight
            heavy_key = key
        end
    end)
    if total_weight == heavy_weight then
        heavy_key = nil
    end

    self.is_eastward = false
    room:each_child(function (key, child)
        if key ~= heavy_key then
            self.y = y - 1
            self.items = items
            self.enemies = enemies
            if child.class == 'Room' then
                x1 = self.x
                doors[x1] = doors[x1] or {}
                self.doors = doors[x1]
            end
            child:accept(self)
        end
    end)
    self.x = math.max(self.x, x0 + 1)

    if heavy_key then
        x1, self.y, self.is_eastward = self:get_heavy_child_properties(self.x, y)
        doors[x1] = doors[x1] or {}
        self.doors = doors[x1]
        room.children[heavy_key]:accept(self)
    end

    for x = x1, x0, -1 do
        doors[x] = doors[x] or {}
        if x == x0 then
            if is_eastward then
                doors[x].west = Util.filter_keys(room, {'open'})
            else
                doors[x].south = Util.filter_keys(room, {'open'})
            end
        end
        if x < x1 then doors[x].east = {} end
        if x > x0 then doors[x].west = {} end
        if doors[x].north then
            doors[x].north.name = string.format('door_%d_%d_n', x, y)
        end
        self.render{
            x=x,
            y=y,
            doors=doors[x],
            items=items,
            enemies=enemies,
        }
        local savegame_variable = room.savegame_variable .. '_' .. (x - x0)
        add_doorway(self.separators, x,   y+1, 'north', doors[x].south and savegame_variable or false)
        add_doorway(self.separators, x,   y,   'east',  doors[x].west  and savegame_variable or false)
        add_doorway(self.separators, x,   y,   'south', doors[x].north and savegame_variable or false)
        add_doorway(self.separators, x+1, y,   'west',  doors[x].east  and savegame_variable or false)
        items = {}
        enemies = {}
    end

end


Layout.AlphaVisitor = BaseVisitor:new()

function Layout.AlphaVisitor:get_heavy_child_properties(x, y)
    return x,     y - 1, false
end


Layout.BetaVisitor = BaseVisitor:new()

function Layout.BetaVisitor:get_heavy_child_properties(x, y)
    return x - 1, y,     true
end

return Layout

local enemy = ...

-- Gibdo.

sol.main.load_file("enemies/generic_towards_hero")(enemy)
enemy:set_properties({
  sprite = "enemies/gibdo",
  life = 4,
  damage = 4,
  normal_speed = 40,
  faster_speed = 48,
  pushed_when_hurt = false
})


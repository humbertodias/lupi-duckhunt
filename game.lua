-- Duck Hunt for the Lupi console (480x270, 60 fps).
-- D-pad or left stick aims, and so does the mouse. B or the left button shoots.
-- A, B, or a click restarts.

require "palette"
local Sprites = require "sprites"
local Dog = Sprites.img.dog
local Duck = Sprites.img.duck
local Hud = Sprites.img.hud

local W, H = 480, 270
local SX, SY = W / 800, H / 500

local WHITE = Palette.hex(0xFFFFFF)
local GREEN = Palette.hex(0x9AE900)

local INTRO_FRAMES = 120
local ROUND_FRAMES = 600
local DOG_STEP = 18
local DUCK_STEP = 10
local AIM_SPEED = 3

local function ox(v) return v * SX end
local function oy(v) return v * SY end

local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function play_fx(name)
  if sfx and sfx.fx then sfx.fx("sfx/" .. name) end
end

local function play_music(name)
  if not (sfx and sfx.music) then return end
  if name then
    sfx.music("sfx/" .. name)
  else
    sfx.music(-1)
  end
end

local function fly_index(anim)
  local m = anim % 4
  if m == 3 then return 1 end
  return m
end

local function apply_palette()
  for i = 1, #Palette do
    ui.palset(i - 1, Palette[i])
  end
end

local function draw_spr(group, name, x, y, flip)
  local spr = group[name]
  if not spr then return end
  ui.spr(spr, math.floor(x), math.floor(y), flip and true or false)
end

local round_num = 1
local score = 0
local phase = "intro"
local intro_clock = 0
local dog_anim = 0
local dog_x, dog_y = ox(250), oy(350)
local notice = { "ROUND", "1" }

local aim_x, aim_y = W / 2, H / 2
local mouse_shot = false
local rounds = 3
local ducks = {}
local hit = {}
local hit_index = 0
local play_clock = 0
local dog_out = false
local dog_pop = 0
local dog_kind = "laugh"
local bark_count = 0
local end_clock = 0

local function reset_hits()
  hit = {}
  for i = 1, 10 do hit[i] = false end
  hit_index = 0
end

local function make_duck()
  local duck = {
    x = (math.random(0, 1) == 0) and 0 or W,
    y = math.random(0, math.floor(H / 2)),
    dx = 0,
    dy = 0,
    frame = 0,
    anim = 0,
    dead = false,
    finished = false,
    fly_off = false,
    just_shot = false,
    flip = false,
  }

  local function change_direction()
    if duck.frame ~= 0 then return end
    local spr = Duck.fly_0
    local fw, fh = spr.width, spr.height

    if duck.fly_off then
      duck.dx, duck.dy = 0, oy(-4)
      return
    end
    if duck.dead then
      duck.dx, duck.dy = 0, oy(4)
      return
    end

    local function speed()
      return (4 + round_num) + math.random(0, 1)
    end

    if duck.x <= 0 then
      repeat
        duck.dx = ox(speed())
        duck.dy = oy(math.random(-4, 4))
      until duck.dy ~= 0
    elseif duck.x + fw > W then
      repeat
        duck.dx = ox(-speed())
        duck.dy = oy(math.random(-4, 4))
      until duck.dy ~= 0
    elseif duck.y <= 0 then
      repeat
        local coin = (math.random(0, 1) == 0) and -1 or 1
        duck.dx = ox(speed() * coin)
        duck.dy = oy(math.random(2, 4))
      until duck.dx ~= 0
    elseif duck.y > H / 2 then
      repeat
        local coin = (math.random(0, 1) == 0) and -1 or 1
        duck.dx = ox(speed() * coin)
        duck.dy = oy(math.random(-4, -2))
      until duck.dx ~= 0
    end

    if duck.dx < 0 then
      duck.flip = true
    elseif duck.dx > 0 then
      duck.flip = false
    end
  end

  duck.change_direction = change_direction
  change_direction()
  return duck
end

local function duck_hit(duck)
  if duck.fly_off or duck.dead then return false end
  local spr = Duck.fly_0
  local x2, y2 = aim_x, aim_y
  if x2 < duck.x or x2 > duck.x + spr.width then return false end
  if y2 < duck.y or y2 > duck.y + spr.height then return false end
  duck.dead = true
  duck.just_shot = true
  duck.frame = 1
  duck.dx, duck.dy = 0, oy(4)
  return true
end

local function update_duck(duck)
  local spr = Duck.fly_0
  local x, y = duck.x, duck.y
  duck.frame = (duck.frame + 1) % DUCK_STEP
  duck.x = x + duck.dx
  duck.y = y + duck.dy
  if not duck.dead or not duck.finished then
    duck.change_direction()
  end
  if duck.frame == 0 then
    duck.anim = duck.anim + 1
    if not duck.dead and not duck.fly_off and duck.anim % 4 == 0 then
      play_fx("quack")
    end
  end
  local past_left = (x + spr.width) < 0
  local past_top = (y + spr.height) < 0
  local past_right = x > W
  if duck.fly_off and (past_left or past_top or past_right) then
    duck.finished = true
  end
end

local function draw_duck(duck)
  if duck.finished then return end
  if not duck.dead then
    local prefix = duck.fly_off and "up_" or "fly_"
    draw_spr(Duck, prefix .. fly_index(duck.anim), duck.x, duck.y, duck.flip)
    return
  end

  if duck.just_shot then
    if duck.frame == 0 then duck.just_shot = false end
    duck.y = duck.y - duck.dy
    draw_spr(Duck, "hit", duck.x, duck.y, false)
    return
  end

  if duck.y < H / 2 then
    draw_spr(Duck, "fall", duck.x, duck.y, false)
  else
    if not duck.finished then play_fx("drop") end
    duck.finished = true
  end
end

local function shoot()
  if rounds <= 0 then return false end
  rounds = rounds - 1
  play_fx("blast")
  return true
end

local function spawn_pair()
  ducks = { make_duck(), make_duck() }
  play_clock = 0
  rounds = 3
  dog_out = false
  dog_pop = 0
end

local function begin_round()
  phase = "intro"
  intro_clock = 0
  dog_anim = 0
  bark_count = 0
  dog_x, dog_y = ox(250), oy(350)
  notice = { "ROUND", tostring(round_num) }
  reset_hits()
end

local function draw_hud()
  draw_spr(Hud, "shot", ox(60), oy(440), false)
  draw_spr(Hud, "score", ox(620), oy(440), false)
  draw_spr(Hud, "hitbar", ox(245), oy(440), false)

  for i = 0, rounds - 1 do
    draw_spr(Hud, "bullet", ox(60) + ox(10) + ox(i * 18), oy(440) + oy(5), false)
  end

  local icons_x, icons_y = ox(329), oy(445)
  for i = 1, 10 do
    local name = hit[i] and "red" or "white"
    draw_spr(Hud, name, icons_x + ox((i - 1) * 18), icons_y, false)
  end

  ui.print("R=" .. round_num, math.floor(ox(60)), math.floor(oy(410)), GREEN)
  local text = tostring(score)
  ui.print(text, math.floor(ox(730) - #text * 6), math.floor(oy(442)), WHITE)
end

local function draw_notice()
  if not notice then return end
  local spr = Hud.notice
  local x, y = ox(370), oy(120)
  ui.spr(spr, math.floor(x), math.floor(y), false)
  local line1 = tostring(notice[1] or "")
  local line2 = tostring(notice[2] or "")
  ui.print(line1, math.floor(x + (spr.width - #line1 * 6) / 2), math.floor(y + 6), WHITE)
  if line2 ~= "" then
    ui.print(line2, math.floor(x + (spr.width - #line2 * 6) / 2), math.floor(y + 18), WHITE)
  end
end

local function draw_cross()
  local spr = Sprites.img.cross
  ui.spr(spr, math.floor(aim_x - spr.width / 2), math.floor(aim_y - spr.height / 2), false)
end

local function move_aim()
  if ui.btn(LEFT) then aim_x = aim_x - AIM_SPEED end
  if ui.btn(RIGHT) then aim_x = aim_x + AIM_SPEED end
  if ui.btn(UP) then aim_y = aim_y - AIM_SPEED end
  if ui.btn(DOWN) then aim_y = aim_y + AIM_SPEED end

  if ui.pointer then
    local x, y, shot, absolute = ui.pointer()
    if x ~= nil then
      if absolute then
        aim_x, aim_y = x, y
      else
        aim_x = aim_x + x
        aim_y = aim_y + y
      end
    end
    if shot then mouse_shot = true end
  end

  aim_x = clamp(aim_x, 0, W - 1)
  aim_y = clamp(aim_y, 0, H - 1)
end

local function take_mouse_shot()
  local shot = mouse_shot
  mouse_shot = false
  return shot
end

local function update_intro()
  intro_clock = intro_clock + 1
  if intro_clock % DOG_STEP == 0 then
    dog_anim = dog_anim + 1
  end
  if dog_anim < 5 then
    dog_x = dog_x + SX
  else
    if bark_count < 2 and intro_clock % DOG_STEP == 0 then
      play_fx("bark")
      bark_count = bark_count + 1
    end
    local af = dog_anim % 5
    if af == 1 then
      dog_x = dog_x + ox(5)
      dog_y = dog_y - oy(10)
    elseif af == 2 then
      dog_x = dog_x + ox(5)
      dog_y = dog_y + oy(5)
    end
  end
  if intro_clock > INTRO_FRAMES then
    spawn_pair()
    phase = "play"
    notice = nil
  end
end

local function draw_intro_dog()
  if dog_anim < 5 then
    draw_spr(Dog, "walk_" .. dog_anim, dog_x, dog_y, false)
    return
  end
  local af = dog_anim % 5
  if af > 2 then return end
  draw_spr(Dog, "jump_" .. af, dog_x, dog_y, false)
end

local function both_done()
  local first, second = ducks[1], ducks[2]
  if not first or not second then return false end
  return first.finished and second.finished
end

local function update_play()
  move_aim()
  local shot = take_mouse_shot() or ui.btnp(BTN_Z)
  if shot and not dog_out then
    local fired = shoot()
    for _, duck in ipairs(ducks) do
      if fired and duck_hit(duck) then
        score = score + 10
        play_fx("point")
        if hit_index < 10 then
          hit_index = hit_index + 1
          hit[hit_index] = true
        end
      elseif not duck.dead and rounds <= 0 then
        duck.fly_off = true
      end
    end
  end

  if dog_out then
    local kind_h = Dog[dog_kind].height
    dog_pop = dog_pop + oy(3)
    if dog_pop < kind_h then
      dog_y = dog_y - oy(3)
    else
      dog_y = dog_y + oy(3)
      local visible = kind_h - (dog_pop - kind_h)
      if visible <= 0 then
        dog_x, dog_y = ox(450), oy(325)
        dog_pop = 0
        dog_out = false
        spawn_pair()
      end
    end
    return
  end

  play_clock = play_clock + 1
  for _, duck in ipairs(ducks) do
    update_duck(duck)
  end

  local times_up = play_clock > ROUND_FRAMES
  if not (times_up or both_done()) then return end

  for _, duck in ipairs(ducks) do
    if not duck.finished and not duck.dead then
      duck.fly_off = true
      return
    end
  end

  for _, duck in ipairs(ducks) do
    if not duck.dead then
      hit_index = hit_index + 1
    end
  end

  if hit_index >= 9 then
    local missed = 0
    for i = 1, 10 do
      if not hit[i] then missed = missed + 1 end
    end
    if missed >= 4 then
      phase = "gameover"
      notice = { "GAME OVER", "" }
      play_music("gameover")
    else
      phase = "roundend"
      end_clock = 0
      notice = nil
      play_music("next-round")
    end
    return
  end

  local killed = 0
  for _, duck in ipairs(ducks) do
    if duck.dead then killed = killed + 1 end
  end
  if killed >= 2 then
    dog_kind = "two"
  elseif killed == 1 then
    dog_kind = "one"
  else
    dog_kind = "laugh"
  end
  if killed == 0 then
    play_fx("flyaway")
  else
    play_fx("hit")
  end
  dog_out = true
  dog_pop = 0
  dog_x, dog_y = ox(450), oy(325)
end

local function draw_dog_out()
  local spr = Dog[dog_kind]
  local visible = spr.height
  if dog_pop < spr.height then
    visible = dog_pop
  else
    visible = spr.height - (dog_pop - spr.height)
  end
  if visible <= 1 then return end
  ui.clip(0, math.floor(dog_y), W, math.floor(visible))
  ui.spr(spr, math.floor(dog_x), math.floor(dog_y), false)
  ui.clip()
end

local function update_roundend()
  end_clock = end_clock + 1
  if end_clock > 60 then
    round_num = round_num + 1
    begin_round()
  end
end

local function update_gameover()
  if take_mouse_shot() or ui.btnp(BTN_Z) or ui.btnp(BTN_X) then
    score = 0
    round_num = 1
    begin_round()
  end
end

function update()
  apply_palette()
  ui.camera()
  ui.clip()

  if phase == "intro" then
    move_aim()
    take_mouse_shot()
    update_intro()
  elseif phase == "play" then
    update_play()
  elseif phase == "roundend" then
    move_aim()
    take_mouse_shot()
    update_roundend()
  elseif phase == "gameover" then
    move_aim()
    update_gameover()
  end

  ui.spr(Sprites.img.bg, 0, 0, false)

  if phase == "intro" then
    draw_intro_dog()
    ui.print("CLIQUE OU B", 8, 8, WHITE)
  elseif phase == "play" then
    for _, duck in ipairs(ducks) do
      draw_duck(duck)
    end
    if dog_out then draw_dog_out() end
  end

  draw_hud()
  draw_notice()
  if phase == "play" or phase == "intro" then
    draw_cross()
  end
  if phase == "gameover" then
    ui.print("CLIQUE OU A", math.floor(ox(370)), math.floor(oy(200)), WHITE)
  end
end

math.randomseed(os.time())
reset_hits()
begin_round()

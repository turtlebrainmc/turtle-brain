-- Turtle Brain terminal: the AI's face and voice at base.
-- Shows a pixel-art face plus the latest message from the AI
-- (terminal/message.txt on GitHub) on the attached monitor, and posts new
-- messages to chat through a Chat Box.
--
-- message.txt may start with a line like "#face: happy" to set the expression:
-- normal, happy, thinking, worried, error.

local REPO = "https://raw.githubusercontent.com/turtlebrainmc/turtle-brain/main/terminal/"
local CHECK_EVERY = 60 -- seconds between checks for a new message

local mon, chat

local function attach()
  mon = peripheral.find("monitor")
  chat = peripheral.find("chatBox")
end
attach()

local function fetch(name)
  local res = http.get(REPO .. name .. "?t=" .. os.epoch("utc"))
  if not res then
    return nil
  end
  local body = res.readAll()
  res.close()
  return body
end

---------------------------------------------------------------- palette
-- Recolour a few CC colours to match the channel branding.
local function brand(m)
  m.setPaletteColor(colors.black, 0x0E1726)     -- navy background
  m.setPaletteColor(colors.green, 0x2E8B57)     -- shell green
  m.setPaletteColor(colors.lime, 0x7CC96A)      -- light green
  m.setPaletteColor(colors.cyan, 0x5FF5D2)      -- glow teal
  m.setPaletteColor(colors.lightGray, 0x9AA5AD) -- antenna metal
  m.setPaletteColor(colors.brown, 0x163B2A)     -- face shadow
end

---------------------------------------------------------------- face art
-- 16 x 13 pixels. Each pixel is drawn 2 characters wide.
-- Key: . background, L border, D face, E eye, K pupil, W shine, M mouth,
--      A antenna tip, G antenna stem, R red, B brow
local BASE = {
  ".......AA.......",
  ".......GG.......",
  "..LLLLLLLLLLLL..",
  ".LDDDDDDDDDDDDL.",
  ".LDDDDDDDDDDDDL.",
  ".LDWEEDDDDWEEDL.",
  ".LDEKEDDDDEKEDL.",
  ".LDEEEDDDDEEEDL.",
  ".LDDDDDDDDDDDDL.",
  ".LDDDMMMMMMDDDL.",
  ".LDDDDDDDDDDDDL.",
  ".LDDDDDDDDDDDDL.",
  "..LLLLLLLLLLLL..",
}

-- Rows that change per expression: [row] = string
local FACES = {
  normal = {},
  happy = { [6] = ".LDDEDDDDDDEDDL.", [7] = ".LDEDEDDDDEDEDL.", [8] = ".LDDDDDDDDDDDDL.",
            [10] = ".LDDMDDDDDDMDDL.", [11] = ".LDDDMMMMMMDDDL." },
  thinking = { [5] = ".LDDDDDDDDBBBDL.", [6] = ".LDEEWDDDDEEWDL.", [7] = ".LDEEKDDDDEEKDL.",
               [8] = ".LDEEEDDDDEEEDL.", [10] = ".LDDDDDDDMMDDDL." },
  worried = { [5] = ".LDDBBDDDDBBDDL.", [6] = ".LDWEEDDDDWEEDL.", [7] = ".LDEEEDDDDEEEDL.",
              [8] = ".LDEKEDDDDEKEDL.", [10] = ".LDDDDMMMMDDDDL.", [11] = ".LDDDMDDDDMDDDL." },
  error = { [6] = ".LDRDRDDDDRDRDL.", [7] = ".LDDRDDDDDDRDDL.", [8] = ".LDRDRDDDDRDRDL.",
            [10] = ".LDDRRRRRRRRDDL." },
}
local BLINK = { [6] = ".LDDDDDDDDDDDDL.", [7] = ".LDEEEDDDDEEEDL.", [8] = ".LDDDDDDDDDDDDL." }
local TALK = { [10] = ".LDDDMMMMMMDDDL.", [11] = ".LDDDMKKKKMDDDL.", [12] = ".LDDDDMMMMDDDDL." }

local PIX = {
  ["."] = colors.black, L = colors.lime, D = colors.green, E = colors.cyan, K = colors.black,
  W = colors.white, M = colors.cyan, A = colors.cyan, G = colors.lightGray, R = colors.red,
  B = colors.brown,
}

local function buildFace(expr, blink, talk, antennaOn)
  local rows = {}
  for i, r in ipairs(BASE) do
    rows[i] = r
  end
  for i, r in pairs(FACES[expr] or FACES.normal) do
    rows[i] = r
  end
  if blink and expr ~= "error" and expr ~= "happy" then
    for i, r in pairs(BLINK) do
      rows[i] = r
    end
  end
  if talk and expr ~= "error" then
    for i, r in pairs(TALK) do
      rows[i] = r
    end
  end
  if not antennaOn then
    rows[1] = ".......GG......."
  end
  return rows
end

---------------------------------------------------------------- text
local function wrap(text, width)
  local lines = {}
  for para in (text .. "\n"):gmatch("(.-)\n") do
    if para == "" then
      table.insert(lines, "")
    else
      local line = ""
      for word in para:gmatch("%S+") do
        if #line == 0 then
          line = word
        elseif #line + 1 + #word <= width then
          line = line .. " " .. word
        else
          table.insert(lines, line)
          line = word
        end
      end
      table.insert(lines, line)
    end
  end
  return lines
end

---------------------------------------------------------------- layout
local state = { msg = nil, expr = "normal", status = "starting", blink = false, talk = 0, antenna = true }
local layout

local FACE_W, FACE_H = 32, 13

local function computeLayout()
  -- Prefer the face beside the text, then above it; shrink text if needed.
  for _, scale in ipairs({ 1, 0.5 }) do
    mon.setTextScale(scale)
    local w, h = mon.getSize()
    if w >= FACE_W + 24 and h >= FACE_H + 3 then
      layout = { w = w, h = h, fx = 3, fy = math.floor((h - FACE_H) / 2) + 1,
                 tx = FACE_W + 6, tw = w - FACE_W - 7, side = true }
      return
    elseif w >= FACE_W + 2 and h >= FACE_H + 8 then
      layout = { w = w, h = h, fx = math.floor((w - FACE_W) / 2) + 1, fy = 3,
                 tx = 2, ty = FACE_H + 5, tw = w - 2 }
      return
    end
  end
  mon.setTextScale(0.5)
  local w, h = mon.getSize()
  layout = { w = w, h = h, noface = true, tx = 2, ty = 3, tw = w - 2 }
end

local function drawFace()
  if layout.noface then
    return
  end
  local rows = buildFace(state.expr, state.blink, state.talk > 0 and state.talk % 2 == 1, state.antenna)
  for i, r in ipairs(rows) do
    local fg, bg = {}, {}
    for c in r:gmatch(".") do
      local hex = colors.toBlit(PIX[c] or colors.black)
      bg[#bg + 1] = hex .. hex
      fg[#fg + 1] = "00"
    end
    mon.setCursorPos(layout.fx, layout.fy + i - 1)
    mon.blit(string.rep(" ", #r * 2), table.concat(fg), table.concat(bg))
  end
end

local function drawAll()
  if not mon then
    return
  end
  brand(mon)
  computeLayout()
  mon.setBackgroundColor(colors.black)
  mon.clear()
  local w, h = layout.w, layout.h

  -- header bar
  mon.setBackgroundColor(colors.green)
  mon.setTextColor(colors.black)
  mon.setCursorPos(1, 1)
  mon.write(string.rep(" ", w))
  local title = " TURTLE BRAIN "
  mon.setCursorPos(math.max(1, math.floor((w - #title) / 2) + 1), 1)
  mon.write(title)

  drawFace()

  -- message
  mon.setBackgroundColor(colors.black)
  mon.setTextColor(colors.white)
  local lines = wrap(state.msg or "", layout.tw)
  local top = layout.ty or 3
  if layout.side then
    top = math.max(3, math.floor((h - #lines) / 2))
  end
  for i = 1, math.min(#lines, h - top - 1) do
    mon.setCursorPos(layout.tx, top + i - 1)
    mon.write(lines[i])
  end

  -- footer
  mon.setTextColor(colors.cyan)
  mon.setCursorPos(2, h)
  mon.write(state.status:sub(1, w - 2))
end

---------------------------------------------------------------- messages
local function parse(raw)
  raw = raw:gsub("\r", ""):gsub("%s+$", "")
  local expr = "normal"
  local face = raw:match("^#face:%s*(%a+)")
  if face then
    expr = FACES[face] and face or "normal"
    raw = raw:gsub("^#face:[^\n]*\n?", "")
  end
  return raw, expr
end

local function check()
  local raw = fetch("message.txt")
  if not raw then
    if not state.msg then
      state.msg, state.status = "Booting up... waiting for a connection.", "offline"
      drawAll()
    end
    return
  end
  local msg, expr = parse(raw)
  if msg ~= state.msg or expr ~= state.expr then
    local isNew = state.msg ~= nil and msg ~= state.msg
    state.msg, state.expr = msg, expr
    state.status = "Day " .. os.day() .. ", " .. textutils.formatTime(os.time(), false)
    state.talk = 12 -- mouth moves for a few seconds
    drawAll()
    if chat and isNew then
      local first = msg:match("^[^\n]+") or msg
      pcall(chat.sendMessage, first, "Turtle Brain")
    end
  end
end

---------------------------------------------------------------- main loop
check()
local pollTimer = os.startTimer(CHECK_EVERY)
local animTimer = os.startTimer(0.25)
local nextBlink = os.clock() + 3 + math.random() * 3
local nextAntenna = os.clock() + 1

while true do
  local event, param = os.pullEvent()
  if event == "timer" and param == pollTimer then
    check()
    pollTimer = os.startTimer(CHECK_EVERY)
  elseif event == "timer" and param == animTimer then
    local now = os.clock()
    local changed = false
    if state.talk > 0 then
      state.talk = state.talk - 1
      changed = true
    end
    if state.blink then
      state.blink = false
      changed = true
    elseif now >= nextBlink then
      state.blink = true
      nextBlink = now + 3 + math.random() * 4
      changed = true
    end
    if now >= nextAntenna then
      state.antenna = not state.antenna
      nextAntenna = now + 1
      changed = true
    end
    if changed and mon and layout then
      drawFace()
    end
    animTimer = os.startTimer(0.25)
  elseif event == "monitor_resize" or event == "peripheral" or event == "peripheral_detach" then
    attach()
    drawAll()
  end
end

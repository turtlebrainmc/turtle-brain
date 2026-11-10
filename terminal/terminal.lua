-- Turtle Brain terminal: the AI's screen at base.
-- Shows the latest message from the AI (terminal/message.txt on GitHub) on the
-- attached monitor, and posts new messages to chat through a Chat Box.

local REPO = "https://raw.githubusercontent.com/turtlebrainmc/turtle-brain/main/terminal/"
local CHECK_EVERY = 60 -- seconds

local mon = peripheral.find("monitor")
local chat = peripheral.find("chatBox")
if not mon then
  printError("No monitor attached.")
  return
end

local function fetch(name)
  local res = http.get(REPO .. name .. "?t=" .. os.epoch("utc"))
  if not res then
    return nil
  end
  local body = res.readAll()
  res.close()
  return body
end

-- word-wrap text to a width, keeping blank lines
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

local function draw(message, status)
  mon.setTextScale(1)
  mon.setBackgroundColor(colors.black)
  mon.clear()
  local w, h = mon.getSize()

  -- header bar
  mon.setBackgroundColor(colors.green)
  mon.setTextColor(colors.black)
  mon.setCursorPos(1, 1)
  mon.write(string.rep(" ", w))
  local title = " TURTLE BRAIN "
  mon.setCursorPos(math.max(1, math.floor((w - #title) / 2) + 1), 1)
  mon.write(title)

  -- message body
  mon.setBackgroundColor(colors.black)
  mon.setTextColor(colors.white)
  local lines = wrap(message, w - 2)
  for i = 1, math.min(#lines, h - 3) do
    mon.setCursorPos(2, i + 2)
    mon.write(lines[i])
  end

  -- footer
  mon.setTextColor(colors.cyan)
  mon.setCursorPos(2, h)
  mon.write(status:sub(1, w - 2))
end

local last
while true do
  local msg = fetch("message.txt")
  if msg then
    msg = msg:gsub("%s+$", "")
    if msg ~= last then
      local time = textutils.formatTime(os.time(), false)
      draw(msg, "Day " .. os.day() .. ", " .. time)
      if chat and last ~= nil then
        -- first line of each new message goes to chat
        local first = msg:match("^[^\n]+") or msg
        pcall(chat.sendMessage, first, "Turtle Brain")
      end
      last = msg
    end
  elseif not last then
    draw("Booting up... waiting for a connection.", "offline")
  end
  sleep(CHECK_EVERY)
end

-- Turtle Brain logger
-- Every program writes what it does to logs/<program>.log with timestamps,
-- so the AI can read back what happened. To send a log to the AI:
--   pastebin put logs/<program>.log

local log = {}

local LOG_DIR = "logs"
local current

local function who()
  return os.getComputerLabel() or ("#" .. os.getComputerID())
end

local function stamp()
  -- Real-world UTC time, plus the in-game day and clock.
  return ("%s | day %d %s"):format(
    os.date("!%Y-%m-%d %H:%M:%S"),
    os.day(),
    textutils.formatTime(os.time(), true)
  )
end

function log.start(name)
  fs.makeDir(LOG_DIR)
  current = fs.combine(LOG_DIR, name .. ".log")
  log.write(("=== %s started on %s ==="):format(name, who()))
end

function log.write(msg)
  print(msg)
  if current then
    local f = fs.open(current, "a")
    f.writeLine(stamp() .. " | " .. msg)
    f.close()
  end
end

return log

-- Test 1: chop down the tree in front of the turtle and come back.
-- Setup: a felling (axe) turtle facing the bottom log of a tree,
-- with some coal or charcoal in its inventory.

local log = require("lib.log")
log.start("chop")

local function isLog(ok, data)
  if not ok then
    return false
  end
  if data.tags and data.tags["minecraft:logs"] then
    return true
  end
  return data.name:find("log") ~= nil
end

local function ensureFuel(need)
  local level = turtle.getFuelLevel()
  if level == "unlimited" or level >= need then
    return true
  end
  for slot = 1, 16 do
    turtle.select(slot)
    if turtle.refuel(0) then
      turtle.refuel(1)
      while turtle.getFuelLevel() < need and turtle.refuel(1) do end
      if turtle.getFuelLevel() >= need then
        turtle.select(1)
        return true
      end
    end
  end
  turtle.select(1)
  return turtle.getFuelLevel() >= need
end

local function countLogs()
  local total = 0
  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot, true)
    if item and ((item.tags and item.tags["minecraft:logs"]) or item.name:find("log")) then
      total = total + item.count
    end
  end
  return total
end

-- 1. Check the setup.
if not isLog(turtle.inspect()) then
  log.write("No log in front of me. Face me toward a tree trunk and try again.")
  return
end
if not ensureFuel(40) then
  log.write("Not enough fuel. Put coal or charcoal in my inventory.")
  return
end

local before = countLogs()

-- 2. Cut the base and step into the trunk's spot.
turtle.dig()
if not turtle.forward() then
  log.write("Couldn't move into the trunk spot. Something is in the way.")
  return
end
log.write("Cut the base. Climbing the trunk...")

-- 3. Climb, cutting every log above.
local height = 0
while isLog(turtle.inspectUp()) do
  turtle.digUp()
  if not turtle.up() then
    log.write("Blocked while climbing at height " .. height .. ".")
    break
  end
  height = height + 1
end
log.write("Reached the top at height " .. height .. ". Heading down.")

-- 4. Come back down the same way.
for _ = 1, height do
  local tries = 0
  while not turtle.down() do
    turtle.digDown()
    tries = tries + 1
    if tries > 10 then
      log.write("Stuck on the way down. Need a human assist!")
      return
    end
  end
end
turtle.back()

-- 5. Report.
local gained = countLogs() - before
log.write(("Done! Collected %d logs from a tree %d blocks tall. Fuel left: %s."):format(
  gained, height + 1, tostring(turtle.getFuelLevel())))
log.write("Send this log to the AI with: pastebin put logs/chop.log")

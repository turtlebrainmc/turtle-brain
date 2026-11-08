-- Turtle Brain updater
-- Downloads the latest programs from GitHub onto this turtle or computer.
-- First-time install:
--   wget https://raw.githubusercontent.com/turtlebrainmc/turtle-brain/main/update.lua update
-- After that, just run:  update

local REPO = "https://raw.githubusercontent.com/turtlebrainmc/turtle-brain/main/"

local function fetch(path)
  -- The ?t= part asks GitHub for a fresh copy instead of a cached one.
  local url = REPO .. path .. "?t=" .. os.epoch("utc")
  local res, err = http.get(url)
  if not res then
    return nil, err
  end
  local body = res.readAll()
  res.close()
  return body
end

print("Turtle Brain updater")

local manifest, err = fetch("manifest.txt")
if not manifest then
  printError("Could not reach GitHub: " .. tostring(err))
  return
end

local count, failed = 0, 0
for line in manifest:gmatch("[^\r\n]+") do
  local remote, localPath = line:match("^%s*(%S+)%s+(%S+)%s*$")
  if remote and remote:sub(1, 1) ~= "#" then
    local body, ferr = fetch(remote)
    if body then
      local dir = fs.getDir(localPath)
      if dir ~= "" then
        fs.makeDir(dir)
      end
      local f = fs.open(localPath, "w")
      f.write(body)
      f.close()
      print("  got " .. localPath)
      count = count + 1
    else
      printError("  failed " .. remote .. ": " .. tostring(ferr))
      failed = failed + 1
    end
  end
end

print(("Done: %d updated, %d failed."):format(count, failed))
if failed > 0 then
  print("GitHub can take a few minutes to show new code. Try again shortly.")
end

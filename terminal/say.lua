-- say: make the Turtle Brain terminal say something right now.
-- Usage:  say [face] message
-- Faces:  normal, happy, thinking, worried, error
local args = { ... }
if #args == 0 then
  print("Usage: say [face] message")
  print("Faces: normal happy thinking worried error")
  return
end
local faces = { normal = true, happy = true, thinking = true, worried = true, error = true }
local face = "normal"
if faces[args[1]] and #args > 1 then
  face = table.remove(args, 1)
end
local text = table.concat(args, " "):gsub("\\n", "\n")
os.queueEvent("tb_say", text, face)
print("Said it (" .. face .. ").")

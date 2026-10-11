-- Keyring: every addon's minimap button gathered behind one key on the
-- minimap's ring, in a dark drawer that opens beside it. Gather.lua finds the
-- buttons and holds them, Drawer.lua is the key and the drawer, Options.lua
-- the list to leave any out. The settings are the account's (one minimap for
-- every character):
--
--   KeyringSettings = { angle, left = { [frame name] = true } }
--
-- (angle: the key's place around the minimap, in degrees, 190 on the left,
-- clear of the game's buttons; left: the buttons left on the minimap)
local _, ns = ...

ns.ANGLE = 190

function ns.settings()
  if type(KeyringSettings) ~= "table" then KeyringSettings = {} end
  local s = KeyringSettings
  if type(s.angle) ~= "number" then s.angle = ns.ANGLE end
  if type(s.left) ~= "table" then s.left = {} end
  return s
end

-- The events, each listener protected: one's error goes to the game's error
-- handler and never silences the others.
local frame = CreateFrame("Frame")
local listeners = {}

local function run(fn, ...)
  local ok, err = pcall(fn, ...)
  if not ok then geterrorhandler()(err) end
end
ns.run = run

frame:SetScript("OnEvent", function(_, event, ...)
  for _, fn in ipairs(listeners[event]) do
    run(fn, ...)
  end
end)

function ns.on(event, fn)
  if not listeners[event] then
    listeners[event] = {}
    frame:RegisterEvent(event)
  end
  table.insert(listeners[event], fn)
end

function ns.say(text) print("|cffffd100Keyring|r: " .. text) end

SLASH_KEYRING1 = "/keyring"
SlashCmdList.KEYRING = function(msg)
  msg = strtrim(msg or ""):lower()
  if msg == "" then
    ns.toggle()
  elseif msg == "settings" or msg == "options" then
    ns.openOptions()
  elseif msg == "list" then
    local held, left = {}, {}
    for _, e in ipairs(ns.buttons()) do
      table.insert(e.held and held or left, ("%s (%s)"):format(e.label, e.name))
    end
    ns.say(#held == 0 and "no buttons in the drawer." or "in the drawer: " .. table.concat(held, ", ") .. ".")
    if #left > 0 then ns.say("left on the minimap: " .. table.concat(left, ", ") .. ".") end
  elseif msg == "reset" then
    ns.settings().angle = ns.ANGLE
    ns.placeKey()
    ns.say("the key is back in its place.")
  else
    ns.say("/keyring opens the drawer; /keyring settings, list (the buttons), reset (the key's place).")
  end
end

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

-- Every word Keyring shows goes through L, English by default: the client
-- loads its own Text_<locale>.lua next (the TOCs name Text_[TextLocale].lua,
-- scripts/locales.ts writes them from i18n/), which hands its words to
-- ns.translate. A word a translation lacks stays English.
local L = setmetatable({}, { __index = function(_, k) return k end })
ns.L = L
function ns.translate(t)
  for k, v in pairs(t.words or {}) do
    L[k] = v
  end
end

-- A sentence's blanks filled in, in the order its language puts them: the
-- blanks are numbered ("%1$s, %2$d") so a translation may move them, which
-- LuaJIT's format can't read (the game's can). Second Wind's ns.fmt.
function ns.fmt(s, ...)
  if not s:find("%%%d%$") then return s:format(...) end
  local args, order = { ... }, {}
  local plain = s:gsub("%%(%d)%$", function(i)
    table.insert(order, args[tonumber(i)])
    return "%"
  end)
  return plain:format(unpack(order))
end

ns.ANGLE = 190

-- A value of another addon's frame (its strata, level, parent, size), nil when
-- the game hides it: on Forever a frame can answer with a secret value, which
-- no addon may compare, calculate with or use as a table key. What isn't
-- known is skipped, never guessed.
function ns.plain(v)
  if issecretvalue and issecretvalue(v) then return nil end
  return v
end

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

function ns.say(text) print("|cffffd100" .. L["%s:"]:format("Keyring") .. "|r " .. text) end

SLASH_KEYRING1 = "/keyring"
SlashCmdList.KEYRING = function(msg)
  msg = strtrim(msg or ""):lower()
  if msg == "" then
    ns.toggle()
  elseif msg == "settings" or msg == "options" then
    ns.openOptions()
  elseif msg == "list" then
    local held, left, under = {}, {}, {}
    local d = ns.drawer
    for _, e in ipairs(ns.buttons()) do
      local line = ("%s (%s)"):format(e.label, e.name)
      -- (one its addon hides, as the settings page says)
      if not e.shown then line = line .. " " .. L["(hidden by its addon)"] end
      table.insert(e.held and held or left, line)
      -- (one the drawer would cover, which should never be: what holds it)
      -- (a strata or a level the game hides is skipped)
      local b = e.button
      local strata, level = ns.plain(b:GetFrameStrata()), ns.plain(b:GetFrameLevel())
      if e.held and strata and level and (strata ~= d:GetFrameStrata() or level <= d:GetFrameLevel()) then
        table.insert(under, ("%s (%s %d)"):format(e.label, strata, level))
      end
    end
    ns.say(#held == 0 and L["No buttons in the drawer."] or L["In the drawer: %s."]:format(table.concat(held, ", ")))
    if #left > 0 then ns.say(L["Left on the minimap: %s."]:format(table.concat(left, ", "))) end
    if #under > 0 then
      -- (for translators: the layer names, HIGH and the like, stay English, the
      -- numbers are the drawer's own layer and level)
      ns.say(
        ns.fmt(
          L["Buttons the drawer may cover (the drawer at %1$s %2$d): %3$s."],
          d:GetFrameStrata(),
          d:GetFrameLevel(),
          table.concat(under, ", ")
        )
      )
    end
  elseif msg == "reset" then
    ns.settings().angle = ns.ANGLE
    ns.placeKey()
    ns.say(L["The key is back in its place."])
  else
    ns.say(
      L["/keyring opens or closes the drawer. /keyring settings opens the settings. /keyring list shows the buttons in chat. /keyring reset puts the key back in its place."]
    )
  end
end

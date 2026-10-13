-- The buttons: found among the minimap's children (and its backdrop's) and in
-- LibDBIcon's list, gathered into the drawer and held there; one left out
-- (Options.lua) goes back where it was. Never the game's own (tracking, mail,
-- the clock, the zoom...): a frame the game made keeps a secure global name
-- (issecurevariable), an addon's never does. Nor a protected one (it could
-- not be moved or hidden in combat), nor a map pin.
--
-- An addon whose button is held may still try to place it, now and then or
-- on every frame: its SetPoint, ClearAllPoints, SetAllPoints and SetParent do
-- nothing while it is held (the drawer places it with the frame type's own),
-- nor its SetFrameStrata and SetFrameLevel (held above the drawer: lift).
local _, ns = ...

local known = {} -- every button found, by its frame name
local held = {} -- [button] = what it was before: its parent, points, scripts...
local hooked = {}
local seen = {} -- [button] = shown when last laid out

-- (an addon's button by its name; the pins of the map addons end in a number
-- or are named for their addon)
local BUTTON = { "^libdbicon10_", "minimapbutton", "minimapframe", "minimapicon", "[-_]minimap[-_]", "minimap$" }
local PIN = { "%d$", "^handynotes", "^tomtom", "^herebedragons", "^gathermate", "^questie", "^pin" }
local BLOCKED = { "SetPoint", "ClearAllPoints", "SetParent", "SetAllPoints", "SetFrameStrata", "SetFrameLevel" }
-- (bigger than any minimap button: an overlay of the minimap)
local LARGEST = 64

local function nop() end

-- The frame type's own method, whatever the button holds in its place.
local function own(b, method) return getmetatable(b).__index[method] end

local function byName(f)
  if type(f) ~= "table" or type(f.GetName) ~= "function" or f == ns.key then return end
  local name = f:GetName()
  if not name or held[f] or known[name] == f then return name end
  -- selene: allow(global_usage)
  if _G[name] == f and issecurevariable(_G, name) then return end
  if f:IsProtected() then return end
  local w, h = f:GetSize()
  if w > LARGEST or h > LARGEST then return end
  return name
end

local function matches(name, patterns)
  local low = name:lower()
  for _, p in ipairs(patterns) do
    if low:find(p) then return true end
  end
end

local changed

local function libDBIcon() return LibStub and LibStub("LibDBIcon-1.0", true) end

-- A held button above the drawer, its strata and level fixed there, as
-- LibDBIcon r56 fixes its own at MEDIUM and 8 (the drawer, HIGH, would cover
-- one left lower and take its clicks): set with the frame type's own methods,
-- whatever its addon or another one tries since (as the button collectors
-- do), and again at every layout (ns.lift), should the drawer have risen.
local function lift(b)
  own(b, "SetFixedFrameStrata")(b, false)
  own(b, "SetFixedFrameLevel")(b, false)
  own(b, "SetFrameStrata")(b, ns.drawer:GetFrameStrata())
  own(b, "SetFrameLevel")(b, ns.drawer:GetFrameLevel() + 2)
  own(b, "SetFixedFrameStrata")(b, true)
  own(b, "SetFixedFrameLevel")(b, true)
end
function ns.lift(b)
  if held[b] then lift(b) end
end

local function gather(b)
  if held[b] then return end
  local was = {
    parent = b:GetParent(),
    strata = b:GetFrameStrata(),
    level = b:GetFrameLevel(),
    points = {},
    own = {},
    drag = { b:GetScript("OnDragStart"), b:GetScript("OnDragStop") },
    mouseover = b.showOnMouseover,
    fixed = { strata = b:HasFixedFrameStrata(), level = b:HasFixedFrameLevel() },
  }
  for i = 1, b:GetNumPoints() do
    was.points[i] = { b:GetPoint(i) }
  end
  for _, m in ipairs(BLOCKED) do
    was.own[m] = rawget(b, m)
  end
  held[b] = was
  seen[b] = b:IsShown()
  own(b, "SetParent")(b, ns.drawer)
  own(b, "ClearAllPoints")(b)
  lift(b)
  b:SetScript("OnDragStart", nil)
  b:SetScript("OnDragStop", nil)
  for _, m in ipairs(BLOCKED) do
    b[m] = nop
  end
  -- (LibDBIcon's "show on mouse-over" fades a button out off the minimap)
  if b.showOnMouseover then
    b.showOnMouseover = false
    if b.fadeOut then b.fadeOut:Stop() end
    b:SetAlpha(1)
  end
  if not hooked[b] then
    hooked[b] = true
    for _, m in ipairs({ "Show", "Hide", "SetShown" }) do
      hooksecurefunc(b, m, function() changed(b) end)
    end
  end
end

local function release(b)
  local was = held[b]
  if not was then return end
  held[b] = nil
  for _, m in ipairs(BLOCKED) do
    b[m] = was.own[m]
  end
  b:SetFixedFrameStrata(false)
  b:SetFixedFrameLevel(false)
  b:SetParent(was.parent)
  b:SetFrameStrata(was.strata)
  b:SetFrameLevel(was.level)
  b:SetFixedFrameStrata(was.fixed.strata)
  b:SetFixedFrameLevel(was.fixed.level)
  b:ClearAllPoints()
  for _, p in ipairs(was.points) do
    b:SetPoint(unpack(p))
  end
  b:SetScript("OnDragStart", was.drag[1])
  b:SetScript("OnDragStop", was.drag[2])
  if was.mouseover then b.showOnMouseover = true end
  -- (LibDBIcon places its own where its addon keeps it)
  local lib = libDBIcon()
  local broker = b:GetName():match("^LibDBIcon10_(.+)")
  if broker and lib and lib.Refresh and lib:GetMinimapButton(broker) == b then lib:Refresh(broker) end
end

-- A button seen: known from now on, and gathered unless left out.
local function found(b, name)
  local new = known[name] ~= b
  known[name] = b
  if not ns.settings().left[name] then gather(b) end
  return new
end

-- Every button there is now; true when one is new.
function ns.scan()
  local new = false
  local lib = libDBIcon()
  if lib and lib.GetButtonList then
    for _, n in ipairs(lib:GetButtonList()) do
      local b = lib:GetMinimapButton(n)
      local name = byName(b)
      if name and found(b, name) then new = true end
    end
  end
  for _, parent in ipairs({ Minimap, MinimapBackdrop }) do
    for _, f in ipairs({ parent:GetChildren() }) do
      local name = byName(f)
      if name and matches(name, BUTTON) and (name:find("^LibDBIcon10_") or not matches(name, PIN)) then
        if found(f, name) then new = true end
      end
    end
  end
  if new then ns.refresh() end
  return new
end

-- One scan on the next frame, however many asked for it in this one.
local soon
function ns.scanSoon()
  if soon then return end
  soon = true
  C_Timer.After(0, function()
    soon = false
    ns.run(ns.scan)
  end)
end

-- (only when it was shown and is no longer, or the reverse: some addons show
-- their button on every frame)
function changed(b)
  if not held[b] or seen[b] == b:IsShown() then return end
  seen[b] = b:IsShown()
  ns.refresh()
end

-- A button left on the minimap, or taken back into the drawer.
function ns.setLeft(name, left)
  ns.settings().left[name] = left or nil
  local b = known[name]
  if b then
    if left then
      release(b)
    else
      gather(b)
    end
  end
  ns.refresh()
end

-- How the button's addon calls itself: its addon's title when the button's
-- name is that addon's (LibDBIcon's buttons: LibDBIcon10_ and the addon's
-- broker; others: the addon's folder before MinimapButton), else that name.
local SUFFIX = { "minimapbutton", "minimapicon", "minimapframe", "minimap", "button" }
local titles

local function squash(s) return (s:lower():gsub("[^%w]", "")) end

local function plain(s)
  s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "")
  return strtrim(s)
end

local function titleOf(base)
  if not titles then
    titles = {}
    local count = C_AddOns and C_AddOns.GetNumAddOns or GetNumAddOns
    local info = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo
    for i = 1, count() do
      local name, title = info(i)
      if name then titles[squash(name)] = plain(title or name) end
    end
  end
  local key = squash(base)
  local title = titles[key]
  if title and title ~= "" and squash(title):find(key, 1, true) then return title end
end

local function labelOf(name)
  local base = name:gsub("^LibDBIcon10_", "")
  if base == name then
    -- (OldAddon_Minimap_Button: each suffix, then the next)
    local again = true
    while again do
      again = false
      base = base:gsub("^[%s_%-]+", ""):gsub("[%s_%-]+$", "")
      local low = base:lower()
      for _, s in ipairs(SUFFIX) do
        if #low > #s and low:sub(-#s) == s then
          base = base:sub(1, -#s - 1)
          again = true
          break
        end
      end
    end
  end
  if base == "" then base = name end
  return titleOf(base) or base
end

-- The buttons known, by their label: { button, name, label, held, shown }.
function ns.buttons()
  local list = {}
  for name, b in pairs(known) do
    table.insert(list, { button = b, name = name, label = labelOf(name), held = held[b] ~= nil, shown = b:IsShown() })
  end
  table.sort(list, function(a, b)
    if a.label:lower() ~= b.label:lower() then return a.label:lower() < b.label:lower() end
    return a.name < b.name
  end)
  return list
end

-- Placed by the drawer, with the frame type's own methods.
function ns.place(b, ...)
  own(b, "ClearAllPoints")(b)
  own(b, "SetPoint")(b, ...)
end

-- The buttons' icon, for the list (LibDBIcon's .icon; else the button's
-- smallest picture under its ring, the minimap's dark disc aside).
function ns.iconOf(b)
  local icon = b.icon or b.Icon
  if type(icon) == "table" and icon.GetTexture and icon:GetTexture() then return icon end
  local best
  for _, r in ipairs({ b:GetRegions() }) do
    if r:IsObjectType("Texture") then
      local t, layer, w = r:GetTexture(), r:GetDrawLayer(), r:GetWidth()
      local disc = t == 136467 or (type(t) == "string" and t:lower():find("ui%-minimap%-background"))
      if t and not disc and (layer == "ARTWORK" or layer == "BACKGROUND") and w > 0 and w <= 26 then
        if not best or (layer == "ARTWORK" and best:GetDrawLayer() ~= "ARTWORK") then best = r end
      end
    end
  end
  return best
end

ns.on("PLAYER_LOGIN", function()
  -- (the addons that make their button at the login, then those that wait a
  -- moment: Questie's, a second after)
  ns.scanSoon()
  C_Timer.After(1, function() ns.run(ns.scan) end)
  C_Timer.After(5, function() ns.run(ns.scan) end)
  local lib = libDBIcon()
  if lib and lib.RegisterCallback then
    lib.RegisterCallback(ns, "LibDBIcon_IconCreated", function() ns.scanSoon() end)
  end
  ns.on("ADDON_LOADED", function() ns.scanSoon() end)
end)

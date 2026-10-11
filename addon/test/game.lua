-- The fake game Keyring is tested in: frames (parents and children, points,
-- strata, scripts, shown or not), their pictures and texts, the minimap with
-- the game's own buttons on it (their names secure, as the game's are),
-- events, C_Timer (run by G.wait), LibStub with LibDBIcon as it makes its
-- buttons, the Settings API, the mouse (G.mouse: what it is over), and the
-- addon loaded from its TOC (FOREVER=1: Forever's, with its minimap's own
-- frames). G.button() makes a button as our family's addons make theirs.
local G = { chat = {}, timers = {}, now = 0, secure = {}, events = {}, addons = {}, mouse = {} }
local FOREVER = os.getenv("FOREVER") == "1"
G.FOREVER = FOREVER

-- Frames ----------------------------------------------------------------

local methods = {}
local frames = {}

local function region(kind)
  local m = {}
  function m:GetObjectType() return kind end
  function m:IsObjectType(t)
    if t == kind then return true end
    if kind == "Button" or kind == "CheckButton" or kind == "ScrollFrame" then return t == "Frame" end
    return false
  end
  function m:GetParent() return self._parent end
  function m:SetSize(w, h)
    self._w, self._h = w, h
  end
  function m:GetSize() return self._w or 0, self._h or 0 end
  function m:GetWidth() return self._w or 0 end
  function m:GetHeight() return self._h or 0 end
  function m:SetWidth(w) self._w = w end
  function m:SetHeight(h) self._h = h end
  function m:SetPoint(point, rel, relPoint, x, y)
    if type(rel) == "number" then
      rel, relPoint, x, y = nil, nil, rel, relPoint
    elseif type(rel) == "string" then
      rel, relPoint, x, y = self._parent, rel, relPoint, x
    end
    table.insert(self._points, { point, rel or self._parent, relPoint or point, x or 0, y or 0 })
  end
  function m:SetAllPoints(rel) self:SetPoint("TOPLEFT", rel or self._parent, "TOPLEFT", 0, 0) end
  function m:ClearAllPoints() self._points = {} end
  function m:GetNumPoints() return #self._points end
  function m:GetPoint(i) return unpack(self._points[i or 1] or {}) end
  -- (a centre from a CENTER point on a frame whose centre is known)
  function m:GetCenter()
    if self._center then return unpack(self._center) end
    local p = self._points[1]
    if not p or not p[2] then return nil end
    local cx, cy = p[2]:GetCenter()
    if not cx then return nil end
    return cx + p[4], cy + p[5]
  end
  function m:Show()
    local was = self._shown
    self._shown = true
    if not was and self._scripts and self._scripts.OnShow then self._scripts.OnShow(self) end
  end
  function m:Hide()
    local was = self._shown
    self._shown = false
    if was and self._scripts and self._scripts.OnHide then self._scripts.OnHide(self) end
  end
  function m:SetShown(on)
    if on then
      self:Show()
    else
      self:Hide()
    end
  end
  function m:IsShown() return self._shown end
  function m:IsVisible() return self._shown and (not self._parent or self._parent:IsVisible()) end
  function m:SetAlpha(a) self._alpha = a end
  function m:GetAlpha() return self._alpha or 1 end
  function m:SetDrawLayer(l) self._layer = l end
  function m:GetDrawLayer() return self._layer end
  function m:SetTexture(t) self._texture = t end
  function m:GetTexture() return self._texture end
  function m:SetTexCoord(...) self._coord = { ... } end
  function m:GetTexCoord()
    if self._coord then return unpack(self._coord) end
    return 0, 0, 0, 1, 1, 0, 1, 1
  end
  function m:SetVertexColor() end
  function m:SetText(t) self._text = t end
  function m:GetText() return self._text end
  function m:GetStringWidth() return #(self._text or "") * 6 end
  function m:SetJustifyH() end
  function m:SetTextColor() end
  function m:SetWordWrap() end
  return m
end

local function frameMethods(kind)
  local m = region(kind)
  function m:GetName() return self._name end
  function m:SetParent(p)
    if self._parent then
      for i, c in ipairs(self._parent._children) do
        if c == self then
          table.remove(self._parent._children, i)
          break
        end
      end
    end
    self._parent = p
    if p then table.insert(p._children, self) end
  end
  function m:GetChildren() return unpack(self._children) end
  function m:GetRegions() return unpack(self._regions) end
  function m:CreateTexture(_, layer)
    local t = setmetatable({ _points = {}, _shown = true, _parent = self, _layer = layer }, {
      __index = methods.Texture,
    })
    table.insert(self._regions, t)
    return t
  end
  function m:CreateFontString(_, layer)
    local t = setmetatable({ _points = {}, _shown = true, _parent = self, _layer = layer }, {
      __index = methods.FontString,
    })
    table.insert(self._regions, t)
    return t
  end
  function m:SetScript(event, fn) self._scripts[event] = fn end
  function m:GetScript(event) return self._scripts[event] end
  function m:HookScript(event, fn)
    local old = self._scripts[event]
    self._scripts[event] = function(...)
      if old then old(...) end
      fn(...)
    end
  end
  function m:RegisterEvent(e) self._events[e] = true end
  function m:UnregisterEvent(e) self._events[e] = nil end
  function m:IsEventRegistered(e) return self._events[e] == true end
  function m:RegisterForClicks() end
  function m:RegisterForDrag() end
  function m:EnableMouse() end
  function m:SetMovable() end
  function m:SetClampedToScreen() end
  function m:SetFrameStrata(s) self._strata = s end
  function m:GetFrameStrata()
    if self._strata then return self._strata end
    return self._parent and self._parent:GetFrameStrata() or "MEDIUM"
  end
  function m:SetFrameLevel(l) self._level = l end
  function m:GetFrameLevel() return self._level or (self._parent and self._parent:GetFrameLevel() + 1) or 0 end
  function m:SetScale(s) self._scale = s end
  function m:GetScale() return self._scale or 1 end
  function m:GetEffectiveScale() return (self._parent and self._parent:GetEffectiveScale() or 1) * self:GetScale() end
  function m:IsProtected() return self._protected == true, self._protected == true end
  function m:SetHighlightTexture(t) self._highlight = t end
  function m:SetChecked(on) self._checked = on and true or false end
  function m:GetChecked() return self._checked end
  function m:SetScrollChild(c) self._child = c end
  function m:SetBackdrop(b) self._backdrop = b end
  function m:SetBackdropColor(...) self._backdropColor = { ... } end
  function m:SetBackdropBorderColor() end
  function m:CreateAnimationGroup()
    local group = { playing = false }
    function group:Play() self.playing = true end
    function group:Stop() self.playing = false end
    function group:CreateAnimation()
      return setmetatable({}, {
        __index = function()
          return function() end
        end,
      })
    end
    function group:SetToFinalAlpha() end
    return group
  end
  return m
end

methods.Texture = region("Texture")
methods.FontString = region("FontString")
for _, kind in ipairs({ "Frame", "Button", "CheckButton", "ScrollFrame", "GameTooltip" }) do
  methods[kind] = frameMethods(kind)
end

function CreateFrame(kind, name, parent)
  local f = setmetatable({
    _name = name,
    _points = {},
    _children = {},
    _regions = {},
    _scripts = {},
    _events = {},
    _shown = true,
  }, { __index = methods[kind] or methods.Frame })
  if parent then f:SetParent(parent) end
  if name then _G[name] = f end
  table.insert(frames, f)
  return f
end

-- A frame the game made: its name secure.
local function gameFrame(kind, name, parent, w)
  local f = CreateFrame(kind, name, parent)
  f:SetSize(w or 32, w or 32)
  G.secure[name] = true
  return f
end

UIParent = gameFrame("Frame", "UIParent", nil, 0)
UIParent:SetSize(1920, 1080)
UIParent._center = { 960, 540 }
UIParent._scale = 0.75
WorldFrame = gameFrame("Frame", "WorldFrame", nil, 0)
WorldFrame._strata = "BACKGROUND"
MinimapCluster = gameFrame("Frame", "MinimapCluster", UIParent, 192)
Minimap = gameFrame("Frame", "Minimap", MinimapCluster, 140)
Minimap._center = { 1780, 940 }
Minimap._scale = 1.1
MinimapBackdrop = gameFrame("Frame", "MinimapBackdrop", MinimapCluster, 140)
-- The game's own buttons (and one named as an addon's would be, still the game's).
for _, name in ipairs({ "MiniMapTracking", "MiniMapMailFrame", "GameTimeFrame", "MinimapZoomIn", "MinimapZoomOut" }) do
  gameFrame("Button", name, Minimap)
end
gameFrame("Button", "MiniMapWorldMapButton", Minimap)
gameFrame("Button", "MiniMapBattlefieldFrame", Minimap)
if FOREVER then
  gameFrame("Button", "ExpansionLandingPageMinimapButton", MinimapBackdrop)
  gameFrame("DropdownButton", "AddonCompartmentFrame", MinimapCluster)
end
GameTooltip = gameFrame("GameTooltip", "GameTooltip", UIParent)
function GameTooltip:SetOwner(owner)
  self._owner, self._lines = owner, {}
end
function GameTooltip:AddLine(text) table.insert(self._lines, text) end

function issecurevariable(t, name)
  if t ~= _G then return false end
  return G.secure[name] == true
end

-- The game's functions ----------------------------------------------------

UISpecialFrames = {}
SlashCmdList = {}

function print(...)
  local parts = {}
  for i = 1, select("#", ...) do
    parts[i] = tostring(select(i, ...))
  end
  table.insert(G.chat, table.concat(parts, " "))
end

function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

function geterrorhandler()
  return function(err) error(err, 0) end
end

function hooksecurefunc(t, name, fn)
  if type(t) == "string" then
    t, name, fn = _G, t, name
  end
  local old = t[name]
  t[name] = function(...)
    local r = { old(...) }
    fn(...)
    return unpack(r)
  end
end

function GetMouseFoci() return G.mouse end
function GetCursorPosition() return G.cursor and G.cursor[1] or 0, G.cursor and G.cursor[2] or 0 end
function InCombatLockdown() return false end

C_Timer = {}
function C_Timer.After(s, fn) table.insert(G.timers, { at = G.now + s, fn = fn }) end

C_AddOns = {}
function C_AddOns.GetNumAddOns() return #G.addons end
function C_AddOns.GetAddOnInfo(i)
  local a = G.addons[i]
  if a then return a[1], a[2] end
end

Settings = { categories = {} }
function Settings.RegisterCanvasLayoutCategory(frame, name)
  local c = { frame = frame, name = name, id = #Settings.categories + 1 }
  function c:GetID() return self.id end
  table.insert(Settings.categories, c)
  return c
end
function Settings.RegisterAddOnCategory(c) c.registered = true end
function Settings.OpenToCategory(id)
  G.opened = id
  Settings.categories[id].frame:Show()
end

-- LibStub, and LibDBIcon making its buttons as it does (LibDBIcon-1.0 r55).
local libs = {}
LibStub = setmetatable({}, {
  __call = function(_, major, silent)
    if not libs[major] and not silent then error("no " .. major) end
    return libs[major]
  end,
})

local DBIcon = { objects = {}, callbacks = {} }
libs["LibDBIcon-1.0"] = DBIcon
function DBIcon.RegisterCallback(owner, event, fn) DBIcon.callbacks[event] = { owner = owner, fn = fn } end
local function updatePosition(button, position)
  local angle = math.rad(position or 225)
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * 80, math.sin(angle) * 80)
end
G.updatePosition = updatePosition
function DBIcon:Register(name, object, db)
  local button = CreateFrame("Button", "LibDBIcon10_" .. name, Minimap)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  button:SetSize(31, 31)
  local overlay = button:CreateTexture(nil, "OVERLAY")
  overlay:SetSize(50, 50)
  overlay:SetTexture(136430)
  local background = button:CreateTexture(nil, "BACKGROUND")
  background:SetSize(24, 24)
  background:SetTexture(136467)
  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetSize(18, 18)
  icon:SetTexture(object.icon)
  button.icon = icon
  button.dataObject = object
  button.db = db
  button:SetScript("OnDragStart", function() end)
  button:SetScript("OnDragStop", function() end)
  button.fadeOut = button:CreateAnimationGroup()
  DBIcon.objects[name] = button
  if DBIcon.loggedIn then updatePosition(button, db and db.minimapPos) end
  local c = DBIcon.callbacks.LibDBIcon_IconCreated
  if c then c.fn("LibDBIcon_IconCreated", button, name) end
  return button
end
function DBIcon:ShowOnEnter(name, on)
  local button = self.objects[name]
  button.showOnMouseover = on
  button:SetAlpha(on and 0 or 1)
end
function DBIcon:Refresh(name)
  local button = self.objects[name]
  updatePosition(button, button.db and button.db.minimapPos)
  button:SetShown(not (button.db and button.db.hide))
end
function DBIcon:GetMinimapButton(name) return self.objects[name] end
function DBIcon:GetButtonList()
  local t = {}
  for name in pairs(self.objects) do
    table.insert(t, name)
  end
  table.sort(t)
  return t
end

-- Our family's buttons, made as their Minimap.lua makes them: placed by
-- their own place() at their angle, dragged by their own scripts.
function G.button(name, angle)
  local b = CreateFrame("Button", name, Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  local icon = b:CreateTexture(nil, "BACKGROUND")
  icon:SetTexture("Interface\\AddOns\\" .. name .. "\\Media\\Logo")
  icon:SetSize(20, 20)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53)
  function b.place()
    local a = math.rad(angle)
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * 80, math.sin(a) * 80)
  end
  b:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", b.place) end)
  b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  b.place()
  return b
end

-- Events, time, the mouse ----------------------------------------------

function G.fire(event, ...)
  for _, f in ipairs(frames) do
    if f._events[event] and f._scripts.OnEvent then f._scripts.OnEvent(f, event, ...) end
  end
end

function G.wait(s)
  G.now = G.now + (s or 0)
  local again = true
  while again do
    again = false
    for i, t in ipairs(G.timers) do
      if t.at <= G.now then
        table.remove(G.timers, i)
        t.fn()
        again = true
        break
      end
    end
  end
end

-- A click: the mouse down over these frames (none: the world), then the
-- frame's own click.
function G.click(frame, mouse, over)
  G.mouse = over or { frame }
  G.fire("GLOBAL_MOUSE_DOWN", mouse or "LeftButton")
  if frame and frame._scripts.OnClick then frame._scripts.OnClick(frame, mouse or "LeftButton") end
end

function G.slash(msg) SlashCmdList.KEYRING(msg) end

-- The addon ---------------------------------------------------------------

function G.load()
  local dir = "addon/Keyring/"
  local toc = io.open(dir .. (FOREVER and "Keyring_Camelot.toc" or "Keyring_Vanilla.toc")):read("*a")
  local ns = {}
  for line in toc:gmatch("[^\n]+") do
    if not line:find("^#") then
      local chunk = assert(loadfile(dir .. line))
      chunk("Keyring", ns)
    end
  end
  G.ns = ns
  return ns
end

function G.login()
  G.fire("ADDON_LOADED", "Keyring")
  G.fire("PLAYER_LOGIN")
  DBIcon.loggedIn = true
  for _, b in pairs(DBIcon.objects) do
    updatePosition(b, b.db and b.db.minimapPos)
  end
  G.wait(0)
end

G.DBIcon = DBIcon
return G

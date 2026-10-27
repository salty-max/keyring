-- The key on the minimap's ring (the ring and highlight of the game's own
-- minimap buttons, the project's keyring icon; drag it around the minimap)
-- and the drawer it opens beside it: a dark tooltip's frame, the gathered
-- buttons in a grid as square as their number allows, at the minimap's own
-- scale. Closed by the key, by Escape, or by a click anywhere else but on a
-- menu or a tooltip (a gathered button may have opened one, and hiding the
-- button would close its menu).
local _, ns = ...
local L = ns.L

local ICON = "Interface\\AddOns\\Keyring\\Media\\Logo"
-- (the key a third larger than the game's buttons, all of it: the ring, the
-- icon, its place inside the ring)
local BIG = 1.3
-- (inside the border; between two buttons)
local PAD = 8
local GAP = 2
-- (where a gathered button's menu or tooltip lives)
local SPARED = { FULLSCREEN_DIALOG = true, TOOLTIP = true }

local key

local drawer = CreateFrame("Frame", "KeyringDrawer", UIParent, "BackdropTemplate")
drawer:SetFrameStrata("HIGH")
drawer:SetClampedToScreen(true)
drawer:EnableMouse(true)
drawer:Hide()
drawer:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 16,
  edgeSize = 16,
  insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
drawer:SetBackdropColor(0.02, 0.02, 0.03, 0.94)
drawer:SetBackdropBorderColor(0.5, 0.5, 0.5)
ns.drawer = drawer
-- (Escape closes it)
table.insert(UISpecialFrames, "KeyringDrawer")

local empty = drawer:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
empty:SetPoint("CENTER")
empty:SetText(L["No addon's button yet"])

-- The gathered buttons shown (an addon may hide its own), in a grid.
function ns.layout()
  local shown = {}
  local cell = 0
  for _, e in ipairs(ns.buttons()) do
    if e.held and e.shown then
      table.insert(shown, e.button)
      local w, h = e.button:GetSize()
      cell = math.max(cell, w, h)
    end
  end
  local n = #shown
  if n == 0 then
    empty:Show()
    drawer:SetSize(empty:GetStringWidth() + 2 * PAD + 8, 40)
    return
  end
  empty:Hide()
  cell = cell + GAP
  local columns = math.ceil(math.sqrt(n))
  local rows = math.ceil(n / columns)
  for i, b in ipairs(shown) do
    local column, row = (i - 1) % columns, math.floor((i - 1) / columns)
    ns.place(b, "TOPLEFT", drawer, "TOPLEFT", PAD + column * cell, -(PAD + row * cell))
    ns.lift(b)
    b:SetAlpha(1)
  end
  drawer:SetSize(2 * PAD + columns * cell - GAP, 2 * PAD + rows * cell - GAP)
end

-- Beside the key, away from the minimap, toward the middle of the screen.
local function anchor()
  drawer:ClearAllPoints()
  local kx, ky = key:GetCenter()
  local mx, my = Minimap:GetCenter()
  if not (kx and mx) then
    drawer:SetPoint("TOPRIGHT", key, "TOPLEFT", -2, 0)
    return
  end
  local s, u = key:GetEffectiveScale(), UIParent:GetEffectiveScale()
  local v = ky * s > UIParent:GetHeight() * u / 2 and "TOP" or "BOTTOM"
  local h = kx * s > UIParent:GetWidth() * u / 2 and "RIGHT" or "LEFT"
  local dx, dy = kx - mx, ky - my
  if math.abs(dx) >= math.abs(dy) then
    if dx < 0 then
      drawer:SetPoint(v .. "RIGHT", key, v .. "LEFT", -2, 0)
    else
      drawer:SetPoint(v .. "LEFT", key, v .. "RIGHT", 2, 0)
    end
  elseif dy < 0 then
    drawer:SetPoint("TOP" .. h, key, "BOTTOM" .. h, 0, -2)
  else
    drawer:SetPoint("BOTTOM" .. h, key, "TOP" .. h, 0, 2)
  end
end

function ns.open()
  ns.scan()
  drawer:SetScale(Minimap:GetEffectiveScale() / UIParent:GetEffectiveScale())
  anchor()
  ns.layout()
  drawer:Show()
  drawer:RegisterEvent("GLOBAL_MOUSE_DOWN")
end

function ns.close() drawer:Hide() end

function ns.toggle()
  if drawer:IsShown() then
    ns.close()
  else
    ns.open()
  end
end

-- After a button came, went, was left out or taken back: the drawer laid out
-- again if open, the list in the settings too.
function ns.refresh()
  if drawer:IsShown() then ns.layout() end
  if ns.refreshOptions then ns.refreshOptions() end
end

local function within(f, root)
  while f do
    if f == root then return true end
    f = ns.plain(f:GetParent())
  end
end

-- A click elsewhere: not in the drawer, nor on the key, nor on a menu or a
-- tooltip.
local function elsewhere()
  local foci = GetMouseFoci and GetMouseFoci() or { GetMouseFocus and GetMouseFocus() }
  for _, f in ipairs(foci) do
    if within(f, drawer) or within(f, key) then return false end
    local strata = f.GetFrameStrata and ns.plain(f:GetFrameStrata())
    if strata and SPARED[strata] then return false end
  end
  return true
end

drawer:SetScript("OnEvent", function(_, event)
  if event == "GLOBAL_MOUSE_DOWN" and elsewhere() then ns.close() end
end)
drawer:SetScript("OnHide", function(self) self:UnregisterEvent("GLOBAL_MOUSE_DOWN") end)

-- The key: its place around the minimap, kept in the settings.
function ns.placeKey()
  if not key then return end
  local angle = math.rad(ns.settings().angle)
  local r = Minimap:GetWidth() / 2 + 10 + 31 * (BIG - 1) / 2
  key:ClearAllPoints()
  key:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

-- While dragging: the angle from the minimap's centre to the cursor.
local function follow()
  local mx, my = Minimap:GetCenter()
  local cx, cy = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  ns.settings().angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
  ns.placeKey()
end

local function count()
  local n = 0
  for _, e in ipairs(ns.buttons()) do
    if e.held then n = n + 1 end
  end
  return n
end

function ns.createKey()
  if key then return end
  key = CreateFrame("Button", "KeyringMinimapButton", Minimap)
  ns.key = key
  key:SetSize(31 * BIG, 31 * BIG)
  key:SetFrameStrata("MEDIUM")
  key:SetFrameLevel(8)
  key:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  key:RegisterForDrag("LeftButton")
  key:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local icon = key:CreateTexture(nil, "BACKGROUND")
  icon:SetTexture(ICON)
  icon:SetSize(20 * BIG, 20 * BIG)
  icon:SetPoint("TOPLEFT", 7 * BIG, -6 * BIG)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  local border = key:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53 * BIG, 53 * BIG)
  border:SetPoint("TOPLEFT")

  key:SetScript("OnClick", function(_, mouse)
    if mouse == "RightButton" then
      ns.close()
      ns.openOptions()
    else
      ns.toggle()
    end
  end)
  key:SetScript("OnDragStart", function(self)
    ns.close()
    self:SetScript("OnUpdate", follow)
  end)
  key:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  key:SetScript("OnHide", ns.close)
  key:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Keyring")
    local n = count()
    GameTooltip:AddLine(
      n == 0 and L["No buttons gathered yet"] or n == 1 and L["1 button"] or L["%d buttons"]:format(n),
      1,
      1,
      1
    )
    GameTooltip:AddLine(
      L["Click to open the drawer, right-click for the settings. Drag to move the key."],
      0.7,
      0.7,
      0.7,
      true
    )
    GameTooltip:Show()
  end)
  key:SetScript("OnLeave", function() GameTooltip:Hide() end)
  ns.placeKey()
end

ns.on("PLAYER_LOGIN", ns.createKey)

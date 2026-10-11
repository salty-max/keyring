-- The settings page, in the game's Options (AddOns tab): every button found,
-- ticked when it is kept in the drawer; untick one to leave it on the minimap
-- where its addon put it, tick it to take it back. /keyring settings, or a
-- right-click on the key.
local _, ns = ...

local ROW = 26

local panel = CreateFrame("Frame")
panel:Hide()
local category

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Keyring")

local about = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
about:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
about:SetPoint("RIGHT", -16, 0)
about:SetJustifyH("LEFT")
about:SetText(
  "Every addon's minimap button, kept in the drawer the key opens. Untick a button to leave it on the minimap where its addon put it."
)

local scroll = CreateFrame("ScrollFrame", "KeyringOptionsScroll", panel, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", about, "BOTTOMLEFT", 0, -12)
scroll:SetPoint("BOTTOMRIGHT", -32, 16)
local list = CreateFrame("Frame", nil, scroll)
list:SetSize(400, ROW)
scroll:SetScrollChild(list)

local none = list:CreateFontString(nil, "ARTWORK", "GameFontDisable")
none:SetPoint("TOPLEFT", 4, -4)
none:SetText("No addon's minimap button found yet.")

local rows = {}

local function row(i)
  if rows[i] then return rows[i] end
  local r = CreateFrame("Frame", nil, list)
  r:SetSize(400, ROW)
  r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW)
  r.check = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
  r.check:SetSize(24, 24)
  r.check:SetPoint("LEFT")
  r.check:SetScript("OnClick", function(self) ns.setLeft(r.name, not self:GetChecked()) end)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(18, 18)
  r.icon:SetPoint("LEFT", r.check, "RIGHT", 4, 0)
  r.label = r:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  r.label:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
  r.note = r:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  r.note:SetPoint("LEFT", r.label, "RIGHT", 8, 0)
  rows[i] = r
  return r
end

function ns.refreshOptions()
  if not panel:IsShown() then return end
  local buttons = ns.buttons()
  for i, e in ipairs(buttons) do
    local r = row(i)
    r.name = e.name
    r.check:SetChecked(e.held)
    r.label:SetText(e.label)
    local icon = ns.iconOf(e.button)
    if icon then
      r.icon:SetTexture(icon:GetTexture())
      r.icon:SetTexCoord(icon:GetTexCoord())
      r.icon:Show()
    else
      r.icon:Hide()
    end
    r.note:SetText(not e.shown and "(hidden by its addon)" or "")
    r:Show()
  end
  for i = #buttons + 1, #rows do
    rows[i]:Hide()
  end
  none:SetShown(#buttons == 0)
  list:SetSize(scroll:GetWidth() > 0 and scroll:GetWidth() or 400, math.max(1, #buttons) * ROW)
end

panel:SetScript("OnShow", function()
  ns.scan()
  ns.refreshOptions()
end)

function ns.openOptions()
  if category then
    Settings.OpenToCategory(category:GetID())
  else
    ns.say("the settings page needs the game's Options; /keyring list shows the buttons.")
  end
end

ns.on("PLAYER_LOGIN", function()
  if category or not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
  category = Settings.RegisterCanvasLayoutCategory(panel, "Keyring")
  Settings.RegisterAddOnCategory(category)
end)

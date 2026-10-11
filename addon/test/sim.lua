-- Keyring played in the fake game (game.lua): the buttons of a few addons on
-- the minimap with the game's own and some map pins, the login, the key and
-- its drawer, the list in the settings, a reload. FOREVER=1 plays it on
-- Forever (its TOC, its minimap's own frames).
--
--   luajit addon/test/sim.lua
local G = dofile("addon/test/game.lua")

local passed, failed = 0, 0
local function check(what, ok, detail)
  if ok then
    passed = passed + 1
  else
    failed = failed + 1
    io.write(("✗ %s%s\n"):format(what, detail and (": " .. tostring(detail)) or ""))
  end
end
local function eq(what, got, want) check(what, got == want, ("got %s, want %s"):format(tostring(got), tostring(want))) end

-- The installed addons, as the game lists them.
G.addons = {
  { "Hearthtale", "Hearthtale" },
  { "LorekeepersCodex", "Lorekeeper's Codex" },
  { "FieldJournal", "Explorer's Field Journal" },
  { "SecondWind", "Second Wind" },
  { "Questie", "|cFFFFFFFFQuestie|r" },
  { "AtlasLoot", "AtlasLoot |cFF22B14C[Core]|r" },
  { "Keyring", "Keyring" },
}

-- Before the login: our family's buttons, two LibDBIcon ones (one shown only
-- on mouse-over), an old addon's on the minimap's backdrop, a protected one,
-- the map pins of HandyNotes, GatherMate and HereBeDragons, a minimap overlay.
local hearthtale = G.button("HearthtaleMinimapButton", 200)
local codex = G.button("LorekeepersCodexMinimapButton", 200)
local journal = G.button("FieldJournalMinimapButton", 225)
local wind = G.button("SecondWindMinimapButton", 250)
local questie = G.DBIcon:Register("Questie", { icon = "Interface\\Icons\\INV_Misc_Book_07" }, { minimapPos = 180 })
local atlas = G.DBIcon:Register("AtlasLoot", { icon = "Interface\\Icons\\INV_Box_01" }, {})
G.DBIcon:ShowOnEnter("AtlasLoot", true)
local old = CreateFrame("Button", "OldAddon_Minimap_Button", MinimapBackdrop)
old:SetSize(32, 32)
old:SetPoint("TOPLEFT", MinimapBackdrop, "TOPLEFT", 10, -90)
local guarded = CreateFrame("Button", "HearthMinimapButton", Minimap)
guarded:SetSize(31, 31)
guarded._protected = true
local pins = {}
for _, name in ipairs({ "HandyNotesPin12", "GatherMatePin3", "HereBeDragonsMinimapButton", "pinMinimapIcon" }) do
  pins[name] = CreateFrame("Frame", name, Minimap)
end
local overlay = CreateFrame("Frame", "BigMinimapFrame", Minimap)
overlay:SetSize(140, 140)
-- (one of the game's, named as an addon's would be)
G.secure.BlizzardMinimapButton = true
local game = CreateFrame("Button", "BlizzardMinimapButton", Minimap)

local ns = G.load()
G.login()

-- 1. Gathered: every addon's button, never the game's, a pin, an overlay or a
-- protected one.
local drawer = KeyringDrawer
local gathered = {}
for _, e in ipairs(ns.buttons()) do
  if e.held then gathered[e.name] = true end
end
for _, b in ipairs({ hearthtale, codex, journal, wind, questie, atlas, old }) do
  check("gathered: " .. b:GetName(), gathered[b:GetName()])
  eq(b:GetName() .. " in the drawer", b:GetParent(), drawer)
end
for _, b in ipairs({ MiniMapTracking, MiniMapMailFrame, GameTimeFrame, MinimapZoomIn, MiniMapWorldMapButton, game }) do
  eq("the game's own left: " .. b:GetName(), b:GetParent(), Minimap)
end
if G.FOREVER then
  eq("Forever's own left", ExpansionLandingPageMinimapButton:GetParent(), MinimapBackdrop)
  eq("the compartment left", AddonCompartmentFrame:GetParent(), MinimapCluster)
end
for name, pin in pairs(pins) do
  eq("a pin left: " .. name, pin:GetParent(), Minimap)
end
eq("an overlay left", overlay:GetParent(), Minimap)
eq("a protected one left", guarded:GetParent(), Minimap)
eq("the key itself left", KeyringMinimapButton:GetParent(), Minimap)
eq("seven held", #ns.buttons(), 7)

-- 2. The labels: the addon's title when the name is its folder's.
local labels = {}
for _, e in ipairs(ns.buttons()) do
  labels[e.name] = e.label
end
eq("Hearthtale's label", labels.HearthtaleMinimapButton, "Hearthtale")
eq("the Codex's label", labels.LorekeepersCodexMinimapButton, "Lorekeeper's Codex")
eq("the Journal's label", labels.FieldJournalMinimapButton, "Explorer's Field Journal")
eq("Second Wind's label", labels.SecondWindMinimapButton, "Second Wind")
eq("Questie's label (its colour off)", labels.LibDBIcon10_Questie, "Questie")
eq("AtlasLoot's label", labels.LibDBIcon10_AtlasLoot, "AtlasLoot [Core]")
eq("an unknown addon's label", labels.OldAddon_Minimap_Button, "OldAddon")

-- 3. Held: its addon placing it again, dragging it, LibDBIcon refreshing it:
-- it stays.
hearthtale.place()
G.updatePosition(questie, 90)
eq("Hearthtale's place() does nothing", hearthtale:GetNumPoints(), 0)
eq("LibDBIcon's place does nothing", questie:GetNumPoints(), 0)
eq("no drag", hearthtale:GetScript("OnDragStart"), nil)
hearthtale:SetParent(Minimap)
eq("nor its SetParent", hearthtale:GetParent(), drawer)

-- 4. The key opens the drawer: a grid as square as seven allows (3 x 3), in
-- order of their labels, beside the key at the minimap's scale.
local key = KeyringMinimapButton
check("closed at first", not drawer:IsShown())
G.click(key)
check("open", drawer:IsShown())
check("listens for clicks elsewhere", drawer:IsEventRegistered("GLOBAL_MOUSE_DOWN"))
local function at(b)
  local point, rel, relPoint, x, y = b:GetPoint(1)
  return ("%s %s %s %d %d"):format(point, rel == drawer and "drawer" or tostring(rel), relPoint, x, y)
end
-- AtlasLoot [Core], Explorer's Field Journal, Hearthtale, Lorekeeper's Codex,
-- OldAddon, Questie, Second Wind; cells of 32 + 2.
eq("first: AtlasLoot", at(atlas), "TOPLEFT drawer TOPLEFT 8 -8")
eq("second: the Journal", at(journal), "TOPLEFT drawer TOPLEFT 42 -8")
eq("third: Hearthtale", at(hearthtale), "TOPLEFT drawer TOPLEFT 76 -8")
eq("fourth: the Codex, a new row", at(codex), "TOPLEFT drawer TOPLEFT 8 -42")
eq("seventh: Second Wind", at(wind), "TOPLEFT drawer TOPLEFT 8 -76")
eq("drawer width", drawer:GetWidth(), 8 * 2 + 3 * 34 - 2)
eq("drawer height", drawer:GetHeight(), 8 * 2 + 3 * 34 - 2)
eq("at the minimap's scale", drawer:GetScale(), Minimap:GetEffectiveScale() / UIParent:GetEffectiveScale())
eq("AtlasLoot seen (no fading in the drawer)", atlas:GetAlpha(), 1)
check("AtlasLoot no longer fades", not atlas.showOnMouseover)
-- (the key on the left of the minimap, in the screen's top half: the drawer to
-- its left, down from its top)
local point, rel, relPoint = drawer:GetPoint(1)
eq("beside the key", ("%s %s"):format(point, relPoint), "TOPRIGHT TOPLEFT")
eq("anchored to the key", rel, key)

-- 5. An addon hides its button: the drawer closes the gap.
wind:Hide()
eq("six shown: 3 x 2", drawer:GetHeight(), 8 * 2 + 2 * 34 - 2)
wind:Show()
eq("seven again", drawer:GetHeight(), 8 * 2 + 3 * 34 - 2)

-- 6. Clicks: on a gathered button or a menu it opened, it stays; anywhere
-- else, it closes; the key closes it too; Escape knows it.
G.click(hearthtale)
check("a click on a button: open", drawer:IsShown())
local menu = CreateFrame("Frame", nil, UIParent)
menu:SetFrameStrata("FULLSCREEN_DIALOG")
local item = CreateFrame("Button", nil, menu)
G.click(item)
check("a click in a menu: open", drawer:IsShown())
G.click(nil, "LeftButton", { WorldFrame })
check("a click on the world: closed", not drawer:IsShown())
check("no longer listening", not drawer:IsEventRegistered("GLOBAL_MOUSE_DOWN"))
G.click(key)
G.click(key)
check("the key closes it", not drawer:IsShown())
local escape = false
for _, name in ipairs(UISpecialFrames) do
  if name == "KeyringDrawer" then escape = true end
end
check("Escape closes it", escape)
G.click(key)
key:Hide()
check("the key hidden with the minimap: closed", not drawer:IsShown())
key:Show()

-- 7. The settings: the list, ticked; Questie left out goes back to its place,
-- and its addon places it again; taken back, held again.
G.click(key, "RightButton")
check("right-click: the settings", G.opened ~= nil)
check("the settings page registered", Settings.categories[1] and Settings.categories[1].registered)
local function rowOf(name)
  for _, r in ipairs({ Settings.categories[1].frame:GetChildren() }) do
    -- (the scroll frame's child: the list)
    if r._child then
      for _, row in ipairs({ r._child:GetChildren() }) do
        if row.name == name and row:IsShown() then return row end
      end
    end
  end
end
local row = rowOf("LibDBIcon10_Questie")
check("Questie listed", row)
eq("ticked", row and row.check:GetChecked(), true)
eq("labelled", row and row.label:GetText(), "Questie")
eq("its icon", row and row.icon:GetTexture(), "Interface\\Icons\\INV_Misc_Book_07")
eq(
  "Hearthtale's icon",
  rowOf("HearthtaleMinimapButton").icon:GetTexture(),
  "Interface\\AddOns\\HearthtaleMinimapButton\\Media\\Logo"
)
row.check:SetChecked(false)
row.check._scripts.OnClick(row.check)
eq("left out: on the minimap", questie:GetParent(), Minimap)
eq("left out: saved", KeyringSettings.left.LibDBIcon10_Questie, true)
local p, r, _, x, y = questie:GetPoint(1)
eq("back in its place", ("%s %s"):format(p, r and r:GetName()), "CENTER Minimap")
-- (LibDBIcon placed it where Questie keeps it: 180 degrees)
eq("where its addon keeps it", ("%d %d"):format(x, y), "-80 0")
G.updatePosition(questie, 90)
eq("its addon places it again", questie:GetNumPoints(), 1)
check("its drag back", questie:GetScript("OnDragStart") ~= nil)
eq("its level back", questie:GetFrameStrata(), "MEDIUM")
eq("still listed, unticked", rowOf("LibDBIcon10_Questie").check:GetChecked(), false)
row.check:SetChecked(true)
row.check._scripts.OnClick(row.check)
eq("taken back", questie:GetParent(), drawer)
eq("no longer left out", KeyringSettings.left.LibDBIcon10_Questie, nil)
wind:Hide()
eq("a hidden one said so", rowOf("SecondWindMinimapButton").note:GetText(), "(hidden by its addon)")
wind:Show()

-- 8. A button made after the login (LibDBIcon's callback, an addon loaded on
-- demand): gathered on the next frame.
local late = G.DBIcon:Register("Details", { icon = "Interface\\Icons\\INV_Misc_Note_01" }, {})
G.wait(0)
eq("LibDBIcon's late one gathered", late:GetParent(), drawer)
local loaded = G.button("LateAddonMinimapButton", 300)
G.fire("ADDON_LOADED", "LateAddon")
G.wait(0)
eq("an addon loaded later: gathered", loaded:GetParent(), drawer)
local slow = G.button("SlowAddonMinimapButton", 320)
G.wait(1)
eq("one made a moment after the login: gathered", slow:GetParent(), drawer)

-- 9. The slash command: the list, the key's place.
G.chat = {}
G.slash("list")
check("/keyring list", G.chat[1] and G.chat[1]:find("in the drawer: AtlasLoot %[Core%]"), G.chat[1])
KeyringSettings.angle = 30
G.slash("reset")
eq("/keyring reset", KeyringSettings.angle, 190)
G.slash("")
check("/keyring opens it", drawer:IsShown())
G.slash("")

-- 10. A listener's error goes to the game's handler, the others still run.
local ran, errors = false, {}
local handler = geterrorhandler
geterrorhandler = function()
  return function(err) table.insert(errors, err) end
end
ns.on("PLAYER_ENTERING_WORLD", function() error("boom") end)
ns.on("PLAYER_ENTERING_WORLD", function() ran = true end)
G.fire("PLAYER_ENTERING_WORLD")
geterrorhandler = handler
eq("an error reported", #errors, 1)
check("the next listener ran", ran)

-- 11. A reload with Questie left out: it stays on the minimap.
KeyringSettings = { angle = 190, left = { LibDBIcon10_Questie = true } }
local saved = KeyringSettings
G = dofile("addon/test/game.lua")
G.addons = { { "Questie", "Questie" } }
KeyringSettings = saved
local q = G.DBIcon:Register("Questie", { icon = "Interface\\Icons\\INV_Misc_Book_07" }, {})
local h = G.button("HearthtaleMinimapButton", 200)
ns = G.load()
G.login()
eq("after a reload, Questie left out", q:GetParent(), Minimap)
eq("and Hearthtale gathered", h:GetParent(), KeyringDrawer)
G.click(KeyringMinimapButton)
eq("one in the drawer: 1 x 1", KeyringDrawer:GetWidth(), 8 * 2 + 33 - 2)

-- 12. Nothing to gather: the drawer says so.
G = dofile("addon/test/game.lua")
KeyringSettings = nil
ns = G.load()
G.login()
G.click(KeyringMinimapButton)
check("an empty drawer opens", KeyringDrawer:IsShown())
eq("no buttons", #ns.buttons(), 0)

io.write(
  ("%s: %d checks passed%s\n"):format(
    G.FOREVER and "Forever" or "Classic Era",
    passed,
    failed > 0 and (", " .. failed .. " failed") or ""
  )
)
if failed > 0 then os.exit(1) end

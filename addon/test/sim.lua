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
  { "Yonder", "Yonder" },
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
local yonder = G.button("YonderMinimapButton", 225)
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
for _, b in ipairs({ hearthtale, codex, yonder, wind, questie, atlas, old }) do
  check("gathered: " .. b:GetName(), gathered[b:GetName()])
  eq(b:GetName() .. " in the drawer", b:GetParent(), drawer)
  -- (above the drawer, or it would cover them: LibDBIcon's too, their strata
  -- and level fixed)
  check(
    b:GetName() .. " above the drawer",
    b:GetFrameStrata() == drawer:GetFrameStrata() and b:GetFrameLevel() > drawer:GetFrameLevel()
  )
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
eq("the key a third larger", math.floor(KeyringMinimapButton:GetWidth() + 0.5), 40)
eq("seven held", #ns.buttons(), 7)

-- 2. The labels: the addon's title when the name is its folder's.
local labels = {}
for _, e in ipairs(ns.buttons()) do
  labels[e.name] = e.label
end
eq("Hearthtale's label", labels.HearthtaleMinimapButton, "Hearthtale")
eq("the Codex's label", labels.LorekeepersCodexMinimapButton, "Lorekeeper's Codex")
eq("Yonder's label", labels.YonderMinimapButton, "Yonder")
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
-- … and kept there: another addon setting a held button's strata and level
-- back (as some minimap addons do with LibDBIcon's), the drawer risen since.
questie:SetFrameStrata("MEDIUM")
questie:SetFrameLevel(8)
getmetatable(questie).__index.SetFrameStrata(questie, "MEDIUM")
getmetatable(questie).__index.SetFrameLevel(questie, 8)
check(
  "a held button's strata and level set back by another addon: still above the drawer",
  questie:GetFrameStrata() == drawer:GetFrameStrata() and questie:GetFrameLevel() > drawer:GetFrameLevel()
)
drawer:SetFrameLevel(drawer:GetFrameLevel() + 20)
ns.open()
check(
  "the drawer risen: its buttons above it again at the opening",
  questie:GetFrameLevel() > drawer:GetFrameLevel() and hearthtale:GetFrameLevel() > drawer:GetFrameLevel()
)
ns.close()
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
-- AtlasLoot [Core], Hearthtale, Lorekeeper's Codex, OldAddon, Questie,
-- Second Wind, Yonder; cells of 32 + 2.
eq("first: AtlasLoot", at(atlas), "TOPLEFT drawer TOPLEFT 8 -8")
eq("second: Hearthtale", at(hearthtale), "TOPLEFT drawer TOPLEFT 42 -8")
eq("third: the Codex", at(codex), "TOPLEFT drawer TOPLEFT 76 -8")
eq("sixth: Second Wind", at(wind), "TOPLEFT drawer TOPLEFT 76 -42")
eq("seventh: Yonder, a new row", at(yonder), "TOPLEFT drawer TOPLEFT 8 -76")
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
check(
  "… fixed again, as LibDBIcon keeps it",
  questie:GetFrameLevel() == 8 and questie:HasFixedFrameStrata() and questie:HasFixedFrameLevel()
)
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
check("/keyring list", G.chat[1] and G.chat[1]:find("In the drawer: AtlasLoot %[Core%]"), G.chat[1])
check("… no button under the drawer", not table.concat(G.chat, "\n"):find("under the drawer"))
do
  local own = getmetatable(questie).__index
  own.SetFixedFrameStrata(questie, false)
  own.SetFrameStrata(questie, "MEDIUM")
  G.chat = {}
  G.slash("list")
  local said = table.concat(G.chat, "\n")
  check(
    "… one under it named, with what holds it",
    said:find("Under the drawer %(HIGH %d+%): Questie %(MEDIUM %d+%)%."),
    said
  )
  ns.lift(questie)
end
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

-- 12b. Forever's secret values: a button whose strata, level, size and
-- shown state the game hides (a stand-in table that errors on arithmetic and
-- ordering, as a secret does; issecretvalue knows it). Keyring gathers it
-- all the same, lists the buttons, closes on a click on a frame of secret
-- strata, and lets it go, never an error.
local SECRET = setmetatable({}, {
  __add = function() error("secret value used in arithmetic") end,
  __lt = function() error("secret value compared") end,
  __le = function() error("secret value compared") end,
  __concat = function() error("secret value concatenated") end,
})
G = dofile("addon/test/game.lua")
KeyringSettings = nil
G.addons = { { "Yonder", "Yonder" } }
local fine = G.button("HearthtaleMinimapButton", 200)
local hidden = G.button("YonderMinimapButton", 225)
local function hide(f)
  function f:GetFrameStrata() return SECRET end
  function f:GetFrameLevel() return SECRET end
  function f:GetSize() return SECRET, SECRET end
  function f:IsShown() return SECRET end
end
hide(hidden)
-- (one whose size is readable, its strata, level and shown state not)
local secretive = G.button("SecondWindMinimapButton", 250)
function secretive:GetFrameStrata() return SECRET end
function secretive:GetFrameLevel() return SECRET end
function secretive:IsShown() return SECRET end
local savedSecretValue = issecretvalue
issecretvalue = function(v) return rawequal(v, SECRET) end
ns = G.load()
local logged, err = pcall(G.login)
check("a login with secret values: no error", logged, err)
local held = {}
for _, e in ipairs(ns.buttons()) do
  held[e.name] = e.held
end
check("a plain button still gathered", held.HearthtaleMinimapButton)
check("a button of secret size isn't taken for one", held.YonderMinimapButton == nil)
local after = {}
for _, e in ipairs(ns.buttons()) do
  after[e.name] = e
end
check("a button of secret strata gathered", after.SecondWindMinimapButton and after.SecondWindMinimapButton.held)
check("and counted shown", after.SecondWindMinimapButton and after.SecondWindMinimapButton.shown)
local listed, listErr = pcall(G.slash, "list")
check("/keyring list with secret strata and level: no error", listed, listErr)
for _, line in ipairs(G.chat) do
  check("not listed under the drawer", not line:find("Under the drawer", 1, true), line)
end
local opened, openErr = pcall(G.click, KeyringMinimapButton)
check("the drawer opens", opened and KeyringDrawer:IsShown(), openErr)
local other = CreateFrame("Frame", "SomeMenu", UIParent)
function other:GetFrameStrata() return SECRET end
function other:GetParent() return SECRET end
G.mouse = { other }
local clicked, clickErr = pcall(G.fire, "GLOBAL_MOUSE_DOWN", "LeftButton")
check("a click on a frame of secret strata and parent: no error", clicked, clickErr)
check("and the drawer closes", not KeyringDrawer:IsShown())
local freed, freedErr = pcall(ns.setLeft, "SecondWindMinimapButton", true)
check("a button of secret strata let go: no error", freed, freedErr)
eq("and back on the minimap", secretive:GetParent(), Minimap)
issecretvalue = savedSecretValue

-- 13. A French client: its own language file, every word in French, a word
-- it lacks in English.
G = dofile("addon/test/game.lua")
G.locale = "frFR"
KeyringSettings = nil
local h2 = G.button("HearthtaleMinimapButton", 200)
ns = G.load()
G.login()
GameTooltip._lines = {}
KeyringMinimapButton:GetScript("OnEnter")(KeyringMinimapButton)
eq("the key's tooltip in French", GameTooltip._lines[2], "1 bouton")
eq(
  "its help in French",
  GameTooltip._lines[3],
  ns.L["Click to open the drawer, right-click for the settings. Drag to move the key."]
)
check("… which is French", GameTooltip._lines[3]:find("^Clic pour ouvrir le tiroir"), GameTooltip._lines[3])
G.chat = {}
G.slash("help")
check("/keyring's help in French", G.chat[#G.chat]:find("/keyring ouvre le tiroir%."), G.chat[#G.chat])
G.slash("list")
check("the list in French", table.concat(G.chat, "\n"):find("Dans le tiroir : Hearthtale"), table.concat(G.chat, "\n"))
eq("a word no translation has: English", ns.L["Not a word Keyring says"], "Not a word Keyring says")
check("Hearthtale gathered", h2:GetParent() == KeyringDrawer)

-- 14. A German client: its own file too.
G = dofile("addon/test/game.lua")
G.locale = "deDE"
KeyringSettings = nil
G.button("HearthtaleMinimapButton", 200)
ns = G.load()
G.login()
GameTooltip._lines = {}
KeyringMinimapButton:GetScript("OnEnter")(KeyringMinimapButton)
eq("the key's tooltip in German", GameTooltip._lines[2], "1 Button")
check("… its help in German", GameTooltip._lines[3]:find("^Linksklick öffnet die Schublade"), GameTooltip._lines[3])

-- The German help must retain executable commands and the same checkbox
-- direction: checked gathers a button, unchecked leaves it on the minimap.
G.slash("help")
check(
  "German help: full reset command",
  G.chat[#G.chat]:find("/keyring reset setzt den Schlüssel", 1, true),
  G.chat[#G.chat]
)
G.click(KeyringMinimapButton, "RightButton")
row = rowOf("HearthtaleMinimapButton")
check("German settings: gathered is checked", row and row.check:GetChecked())
row.check:SetChecked(false)
row.check._scripts.OnClick(row.check)
G.slash("list")
check(
  "German settings: unchecked is left on the minimap",
  G.chat[#G.chat]:find("Auf der Minikarte belassen: Hearthtale", 1, true),
  G.chat[#G.chat]
)
row.check:SetChecked(true)
row.check._scripts.OnClick(row.check)
G.slash("list")
check("German list: gathered again", G.chat[#G.chat]:find("In der Schublade: Hearthtale", 1, true), G.chat[#G.chat])
-- A new session without the settings API exercises the actual fallback.
G = dofile("addon/test/game.lua")
G.locale = "deDE"
Settings = nil
KeyringSettings = nil
ns = G.load()
G.login()
G.slash("settings")
check(
  "German settings fallback: unavailable, with a working command",
  G.chat[#G.chat]:find("in diesem Client nicht verfügbar. /keyring list", 1, true),
  G.chat[#G.chat]
)

-- 15. Both Spanish clients load the shared catalog through their own TOC
-- locale file. Exercise player actions so counts, checkbox direction and
-- formatted chat messages are checked after the real translation loader.
for _, locale in ipairs({ "esES", "esMX" }) do
  G = dofile("addon/test/game.lua")
  G.locale = locale
  KeyringSettings = nil
  local first = G.button("HearthtaleMinimapButton", 200)
  local second = G.button("YonderMinimapButton", 225)
  ns = G.load()
  G.login()
  local function tooltip()
    KeyringMinimapButton:GetScript("OnEnter")(KeyringMinimapButton)
    return GameTooltip._lines[2]
  end
  eq(locale .. ": plural tooltip", tooltip(), "2 botones")
  check(locale .. ": translated tooltip help", GameTooltip._lines[3]:find("Arrastra la llave para moverla.", 1, true))
  G.slash("help")
  local help = G.chat[#G.chat]
  for _, command in ipairs({
    "/keyring abre",
    "/keyring settings abre",
    "/keyring list muestra",
    "/keyring reset devuelve",
  }) do
    check(locale .. ": executable help command " .. command, help:find(command, 1, true), help)
  end
  G.click(KeyringMinimapButton, "RightButton")
  local panel = Settings.categories[1].frame
  local about
  for _, region in ipairs({ panel:GetRegions() }) do
    if region:GetText() and region:GetText():find("Desmarca un botón", 1, true) then about = region:GetText() end
  end
  check(locale .. ": settings explain unchecking", about and about:find("para dejarlo en el minimapa", 1, true), about)
  row = rowOf("HearthtaleMinimapButton")
  eq(locale .. ": gathered is checked", row.check:GetChecked(), true)
  second:Hide()
  eq(locale .. ": hidden status", rowOf("YonderMinimapButton").note:GetText(), "(oculto por su addon)")
  second:Show()
  row.check:SetChecked(false)
  row.check._scripts.OnClick(row.check)
  eq(locale .. ": unchecked button on minimap", first:GetParent(), Minimap)
  G.chat = {}
  G.slash("list")
  check(locale .. ": gathered list", G.chat[1]:find("En el cajón: Yonder", 1, true), G.chat[1])
  check(locale .. ": excluded list", G.chat[2]:find("En el minimapa: Hearthtale", 1, true), G.chat[2])
  eq(locale .. ": singular tooltip", tooltip(), "1 botón")
  -- The diagnostic has three typed placeholders. Internal strata tokens
  -- remain unchanged even though the surrounding message is translated.
  local own = getmetatable(second).__index
  own.SetFixedFrameStrata(second, false)
  own.SetFrameStrata(second, "MEDIUM")
  G.slash("list")
  check(
    locale .. ": translated diagnostic with strata and levels",
    G.chat[#G.chat]:find("Cubiertos por el cajón %(HIGH %d+%): Yonder %(MEDIUM %d+%)%."),
    G.chat[#G.chat]
  )
  ns.lift(second)
  ns.setLeft("YonderMinimapButton", true)
  eq(locale .. ": empty tooltip", tooltip(), "Aún no hay botones en el cajón")
  G.slash("")
  local empty
  for _, region in ipairs({ KeyringDrawer:GetRegions() }) do
    if region:GetText() == "No hay botones para mostrar" then empty = region end
  end
  check(locale .. ": empty drawer message", empty and empty:IsShown())
  KeyringSettings.angle = 30
  G.slash("reset")
  eq(locale .. ": reset action", KeyringSettings.angle, 190)
  check(locale .. ": reset message", G.chat[#G.chat]:find("La llave vuelve a su sitio.", 1, true))
  -- Missing Settings API: the translated advice still gives a usable command.
  G = dofile("addon/test/game.lua")
  G.locale = locale
  KeyringSettings = nil
  Settings = nil
  ns = G.load()
  G.login()
  G.slash("settings")
  check(
    locale .. ": settings fallback",
    G.chat[#G.chat]:find("Usa /keyring list para ver los botones.", 1, true),
    G.chat[#G.chat]
  )
end

io.write(
  ("%s: %d checks passed%s\n"):format(
    G.FOREVER and "Forever" or "Classic Era",
    passed,
    failed > 0 and (", " .. failed .. " failed") or ""
  )
)
if failed > 0 then os.exit(1) end

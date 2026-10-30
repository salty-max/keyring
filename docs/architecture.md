# Keyring's architecture

The addon file by file (moved from CLAUDE.md on 20 October 2026; the map
stays there).

- `addon/Keyring/`: one folder for every game, installable as is: each game
  loads its own TOC (`Keyring_Vanilla.toc`: Classic Era, 11509; `_Camelot.toc`:
  Forever, 16001), the same but for
  the interface (`scripts/package.ts` checks).
  - `Core.lua`: the settings, the account's (`KeyringSettings`: the key's
    `angle`, the buttons `left` on the minimap by frame name); the events
    (`ns.on`, each listener protected); `/keyring` (settings, list, reset).
  - `Gather.lua`: the buttons found (LibDBIcon's list and its
    `LibDBIcon_IconCreated`; the minimap's and its backdrop's children by
    name, MinimapButton and the like, map pins aside) at the login, a second
    and five after, on every addon loaded and every opening; never the game's
    own (a secure global name: `issecurevariable`), a protected frame, one
    bigger than 64px. Gathered: into the drawer, its addon's `SetPoint`,
    `ClearAllPoints`, `SetParent`, `SetAllPoints` doing nothing while held
    (the drawer places it with the frame type's own, `ns.place`), its drag
    off, LibDBIcon's fade on mouse-over off (a value of its frame the game hides,
    a secret on Forever, is read through `ns.plain` and skipped: a strata or level
    so hidden is not restored), its strata and level held
    above the drawer (`lift`: set with the frame type's own methods and
    fixed there, its own `SetFrameStrata` and `SetFrameLevel` doing nothing
    while held, again at every layout; LibDBIcon r56 fixes them at MEDIUM
    and 8 and another addon may set them back, and the drawer, HIGH, would
    cover the button and take its clicks); left out, all of it back as it
    was. `ns.buttons()` (label: the addon's title when the button is named
    for its folder), `ns.setLeft`, `ns.iconOf`.
  - `Drawer.lua`: the key (the game's minimap button ring and highlight, a
    third larger, `BIG`; the logo, `Media\Logo`; dragged around the minimap) and the
    drawer (`KeyringDrawer`, a dark tooltip backdrop, a square grid, the
    minimap's scale; beside the key away from the minimap; closed by the key,
    Escape, a click elsewhere but on a menu or tooltip: FULLSCREEN_DIALOG or
    TOOLTIP strata, since hiding a button closes the menu it opened).
  - `Options.lua`: the settings page (a canvas in the game's Options): every
    button found, ticked when in the drawer.
- Languages: every word Keyring shows goes through `L["..."]` (`ns.L`,
  Core.lua: English by default, a word a translation lacks stays English).
  The TOCs load `Text_[TextLocale].lua` right after Core.lua: the client
  loads its own language's file. `scripts/locales.ts` (`bun run locales`, its
  `--check` in `bun run check`) writes `Text_<locale>.lua` for the game's
  eleven languages from `i18n/<locale>/words.json` (a stub where there's no
  translation; esMX borrows esES; `meta.json`: `flagged` for one no native
  reader has checked); `--keys` writes `i18n/words.json`, every word to
  translate. No semicolons in any language. The commands stay English. The
  TOCs' `Notes-<locale>` describe it in the addon list. French: done 14
  October 2026, German (flagged) the same day. Spanish: done 16 October 2026,
  flagged until reviewed by a native reader. Neutral Spanish with tú, one
  esES catalog shared by esMX. Use minimapa, botón, cajón, llave and opciones.
  Keep addon names and executable commands unchanged.
- `addon/test/game.lua`: the fake game (frames, the minimap and the game's own
  buttons with secure names, LibStub and LibDBIcon r56 as it makes its buttons, strata and level fixed,
  C_Timer, the Settings API, the mouse); `addon/test/sim.lua` plays it
  (`FOREVER=1` as Forever).
- Release: the BigWigs packager (`.pkgmeta`, `.github/workflows/release.yml`),
  `scripts/release.sh` (`--hold`: GitHub alone; the stores later with
  `gh workflow run release.yml -f tag=vX.Y.Z`).

## Lua tools

- Lua: `bun run format:lua` (StyLua) and `bun run lint:lua` (selene; the
  game's globals in `wow.yml`: add one there when the addon calls a new game
  function). `bun run check` runs everything.

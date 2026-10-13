# Keyring

A World of Warcraft addon: every addon's minimap button gathered behind one
key on the minimap's ring, in a dark drawer that opens beside it; a list in
the settings to leave any out. For Classic Era, TBC Anniversary and World of
Warcraft: Forever. A small sibling of Hearthtale, Lorekeeper's Codex,
Yonder and Second Wind (same release tooling), standalone:
it uses no kit, the game's own look.

## Layout

- `addon/Keyring/`: one folder for every game, installable as is: each game
  loads its own TOC (`Keyring_Vanilla.toc`: Classic Era, 11509; `_TBC.toc`:
  TBC Anniversary, 20506; `_Camelot.toc`: Forever, 16001), the same but for
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
    off, LibDBIcon's fade on mouse-over off; left out, all of it back as it
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
- `addon/test/game.lua`: the fake game (frames, the minimap and the game's own
  buttons with secure names, LibStub and LibDBIcon r55 as it makes its buttons,
  C_Timer, the Settings API, the mouse); `addon/test/sim.lua` plays it
  (`FOREVER=1` as Forever).
- Release: the BigWigs packager (`.pkgmeta`, `.github/workflows/release.yml`),
  `scripts/release.sh` (`--hold`: GitHub alone; the stores later with
  `gh workflow run release.yml -f tag=vX.Y.Z`).

## Conventions

- Lua: `bun run format:lua` (StyLua) and `bun run lint:lua` (selene; the
  game's globals in `wow.yml`: add one there when the addon calls a new game
  function). `bun run check` runs everything.
- Conventional Commits, lowercase subjects; commit locally, ask before any
  push, release or deploy.

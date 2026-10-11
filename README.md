# Keyring

A World of Warcraft addon for Classic Era, TBC Anniversary and World of
Warcraft: Forever: every addon's minimap button gathered behind one key on the
minimap's ring, in a dark drawer that opens beside it. One key to gather them
all, and in the darkness show them.

- **One key**: a minimap button like the game's own (its ring, its highlight, a
  key from the game's icons). Click it for the drawer, right-click for the
  settings, drag it around the minimap.
- **The drawer**: a dark tooltip-like frame beside the key, the buttons in a
  grid as square as their number allows, at the minimap's own scale. Escape,
  the key or a click anywhere else closes it (a click in a menu a button opened
  doesn't).
- **Every addon's button**: those made with LibDBIcon and the others, found on
  the minimap by their names; never the game's own (tracking, mail, the clock,
  the zoom, Forever's addon compartment), never a map pin. A button its addon
  hides stays out of the drawer.
- **Leave any out**: the settings page (Options, AddOns tab) lists every button
  found; untick one and it goes back to its place on the minimap.

`/keyring` opens the drawer; `/keyring settings`, `/keyring list` (the buttons,
gathered and left out), `/keyring reset` (the key's place).

## Development

```bash
bun run check        # format, lint, the simulation on both games, the TOCs
bun run package      # dist/Keyring-<version>.zip, for a test in the game
scripts/release.sh [--version X.Y.Z] [--hold] NOTES.md
```

MIT licensed.

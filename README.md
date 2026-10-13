# Keyring

Keyring collects your World of Warcraft addon minimap buttons into a drawer,
leaving one key button on the minimap. Click it to reach your addons, then
close it with Escape, another click on the key or a click elsewhere.

For Classic Era, Hardcore, Season of Discovery, TBC Anniversary and World of
Warcraft: Forever. One download covers all of them.

## Using Keyring

- **Left-click** the key to open or close the drawer.
- **Right-click** for settings.
- **Drag** the key to move it around the minimap.
- **Untick a button** in settings to leave it on the minimap instead.

The drawer arranges buttons in a grid and follows your minimap's scale.
Clicking a menu opened by an addon button keeps the drawer open so you can
use it.

Keyring finds buttons made with LibDBIcon and other addon buttons it
recognises on the minimap. Tracking, mail, the clock, zoom controls,
Forever's addon compartment and map pins stay where they are. Hidden buttons
stay hidden. Protected buttons are left in place because the game
restricts moving or hiding them during combat.

The key uses the game's minimap ring and highlight, with a painted keyring
icon. It works as soon as you install it.

## Commands

- `/keyring` opens or closes the drawer.
- `/keyring settings` opens the button list.
- `/keyring list` prints gathered and excluded buttons in chat.
- `/keyring reset` returns the key to its default position.

## Download

Get it from [CurseForge](https://www.curseforge.com/projects/1739386),
[Wago](https://addons.wago.io/addons/ANz7JV64) or
[GitHub releases](https://github.com/salty-max/keyring/releases).

Keyring works independently and can gather buttons from Hearthtale,
Lorekeeper's Codex, Yonder, Second Wind and other addons.
The full store description is in [addon/CURSEFORGE.md](addon/CURSEFORGE.md).

## Development

```bash
bun run check        # Check Lua, both game simulations and the TOCs
bun run package      # Create dist/Keyring-<version>.zip
scripts/release.sh [--version X.Y.Z] [--hold] NOTES.md
```

## License

[MIT](LICENSE). Not affiliated with Blizzard Entertainment.

# Keyring

Keyring gathers your addons' minimap buttons into a drawer, leaving one key on
the minimap. Click the key to open the drawer, and close it with Escape,
another click on the key or a click elsewhere.

One download covers Classic Era, Hardcore, Season of Discovery and World of
Warcraft: Forever. Keyring speaks English, French, German and Spanish. Other
clients get English.

## Using Keyring

- **Left-click** the key to open or close the drawer.
- **Right-click** the key for the settings.
- **Drag** the key to move it around the minimap.
- **Untick a button** in the settings to leave it on the minimap instead.

The drawer arranges buttons in a grid and follows your minimap's scale. The
drawer stays open while you use a menu opened from one of its buttons.

Keyring finds buttons made with LibDBIcon, which most addons use, and other
addons' buttons on the minimap that it recognises by name. The game's own
buttons stay where they are: tracking, mail, the clock, the zoom buttons and
Forever's addon compartment. So do map pins and anything over twice the size
of a minimap button. Buttons hidden by their own addon stay hidden. Protected
buttons are left in place because the game restricts moving or hiding them
during combat.

The key uses the game's minimap ring and highlight, with a painted keyring
icon. Keyring works as soon as you install it.

## Commands

- `/keyring` opens or closes the drawer.
- `/keyring settings` opens the settings.
- `/keyring list` shows in chat the buttons in the drawer and those left on the
  minimap.
- `/keyring reset` puts the key back in its place.

## Download

Get it from [CurseForge](https://www.curseforge.com/projects/1739386),
[Wago](https://addons.wago.io/addons/ANz7JV64) or
[GitHub releases](https://github.com/salty-max/keyring/releases).

Keyring needs no other addon.
The full store description is in [addon/CURSEFORGE.md](addon/CURSEFORGE.md).

## Development

```bash
bun run check        # Check the translations, Lua, both game simulations and the TOCs
bun run locales      # Write addon/Keyring/Text_<locale>.lua from i18n/
bun run package      # Create dist/Keyring-<version>.zip
scripts/release.sh --version X.Y.Z [--hold] NOTES.md
```

## License

[MIT](LICENSE). Not affiliated with Blizzard Entertainment.

# Keyring

A World of Warcraft addon: every addon's minimap button gathered behind one
key on the minimap's ring, in a dark drawer that opens beside it; a list in
the settings to leave any out. For Classic Era, TBC Anniversary and World of
Warcraft: Forever. A small sibling of Hearthtale, Lorekeeper's Codex,
Yonder and Second Wind (same release tooling), standalone:
it uses no kit, the game's own look (salty-max/keyring). Read the family's
CLAUDE.md (`../CLAUDE.md`) first.

## Where things are

| What | Where |
|---|---|
| The addon file by file: the TOCs, Core, Gather, Drawer, Options, languages, the tests, the release | `docs/architecture.md` |
| The words to translate | `i18n/<locale>/words.json` (`meta.json`: `flagged`) |
| The store page | `addon/CURSEFORGE.md` |

`docs/` is ignored locally (`.git/info/exclude`): the docs above are
force-added, anything else there is a local note, absent from a worktree.

## Commands

```bash
bun run check        # the kit's scripts (kit:check), then check:ci: languages, lint, the simulation on Classic Era and Forever, TOCs
bun run check:ci     # what CI and the release gate run: no family folder (the kit, the saved ids and the generators' checks aside)
bun "$(git rev-parse --path-format=absolute --git-common-dir)/../../addon-kit/q.ts" check -- bun run check   # the same, quiet, stamping the tree for the push
bun run format:lua   # StyLua
bun run locales      # after a new L["..."] (--keys writes i18n/words.json)
bun run package      # dist/Keyring-<version>.zip for a test in the game
scripts/release.sh [--version X.Y.Z] [--hold] NOTES.md   # check, tag, push; Actions publish
```

## Hard rules

- No kit, no other addon's API: the game's own look and frames. LibDBIcon
  is read as the buttons' maker, never depended on.
- Never gather the game's own buttons (a secure global name), a protected
  frame, or one bigger than 64px. A button left out goes back exactly as it
  was: its own methods, strata and level restored.
- The drawer closes on the key, Escape and a click elsewhere, never on a
  menu or tooltip a button opened.
- Every word through `L`, English by default; no semicolons in any
  language; commands and addon names stay as they are. A new game function
  goes into addon-kit's `wow.yml` (then `bun run kit:sync`).
- `scripts/root.ts`, `scripts/locales-lib.ts` (the family's languages
  core), `scripts/package-lib.ts` (the family's package), `wow.yml` and `stylua.toml` are the kit's copies (`bun run
  kit:sync`, the scripts' alone: Keyring carries no Lua of the kit's);
  Keyring's own globals for selene are `keyring.yml`.
- Conventional Commits, lowercase subjects, no AI trailers. Commit locally;
  ask before any push, release or deploy. The pre-push hook wants a check
  stamp on the tree (q), which `release.sh` makes after the version bump.

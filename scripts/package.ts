/**
 * The addon's package: the family's (scripts/package-lib.ts, the kit's copy):
 * addon/Keyring as it is, one zip for every game, each game loading its own
 * TOC; its TOCs checked.
 *
 *   bun scripts/package.ts           dist/Keyring and dist/Keyring-<version>.zip
 *   bun scripts/package.ts --no-zip  the folder only (to copy into a game)
 *   bun scripts/package.ts --check   the TOCs only
 */
import { join } from "node:path";
import { run } from "./package-lib";

run({ root: join(import.meta.dir, ".."), name: "Keyring", games: { classic: [], tbc: [], forever: [] } });

/**
 * i18n/<locale>/ → addon/Keyring/Text_<locale>.lua, one for every language the
 * game has (a stub where there is no translation yet, so the TOC never names
 * a missing file): each client loads its own, through Text_[TextLocale].lua in
 * the TOCs, and English stays wherever a translation says nothing (Core.lua).
 *
 *   i18n/<locale>/meta.json    { "flagged": true }  (a first translation, not
 *                              reviewed by a native reader)
 *   i18n/<locale>/words.json   { "English": "translation" }: every L["..."] of
 *                              the addon; i18n/words.json lists them
 *
 * A language not given its own folder may borrow another's (esMX: esES).
 *
 *   bun scripts/locales.ts            write the Text files
 *   bun scripts/locales.ts --check    fail if one isn't up to date, a word has
 *                                     no translation, its blanks differ or a
 *                                     semicolon is in it; say what is unused
 *   bun scripts/locales.ts --keys     write i18n/words.json, every word to translate
 *
 * The family's core (scripts/locales-lib.ts, addon-kit's copy: kit:sync
 * --scripts, Keyring carries no Lua of the kit's) reads the words, checks
 * them and writes the files.
 */
import { run } from "./locales-lib";

const ROOT = new URL("..", import.meta.url).pathname;

run({ root: ROOT, addon: "addon/Keyring" });

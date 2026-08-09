# gbs-GlyphTextPlugin

**Version 4.3.0 — Requires GB Studio ≥ 4.3.0**

A GB Studio engine plugin that renders **16×16 text** — every character is a 2×2 quad of
tiles streamed into VRAM as it is printed. Built for scripts that need large character
sets and full-square glyphs: **Chinese, Japanese kanji, Korean**.

It is the [TallTextPlugin](https://github.com/Mico27/gbs-TallTextPlugin) taken one
dimension further, with the tile cache made optional and a glyph source that scales past
what a GB Studio font asset can hold.

---

## Table of Contents

1. [Concepts](#concepts)
2. [Project Setup](#project-setup)
3. [The Generator Tool](#the-generator-tool)
4. [Engine Settings](#engine-settings)
5. [Size Limits and Restrictions](#size-limits-and-restrictions)
6. [Events Reference](#events-reference)
7. [Memory Footprint](#memory-footprint)

---

## Concepts

### Full-square characters

A wide character is four 8×8 tiles arranged 2×2, so a line of text occupies **two tilemap
rows** and each character **two columns**. `\n` moves down a full two-row line; `\r`
scrolls the text area by two rows.

### Why glyph sheets, not font assets

GB Studio's font compiler stores **one byte per image tile** in a font's recode table, so
a font asset can address at most **256 unique tiles** — 64 full-square glyphs. That is
fine for Latin, useless for Chinese.

So wide characters come from a **glyph sheet** instead: an ordinary GB Studio **tileset**
asset holding the 16×16 bitmaps in image order. Tilesets carry a 16-bit tile count and are
addressed by offset, so one sheet holds up to **256 characters** (1024 tiles, one ROM
bank), and several sheets can be registered at once — each covering one contiguous run of
glyph indices. Four slots by default, up to sixteen.

### Two character widths in one line

- **Wide characters** — two bytes, both `≥ 0x80` — come from a glyph sheet and take a
  full 16×16 square.
- **Narrow characters** — one byte, `0x20`–`0x7F` — come from the **current font asset**.
  By default they are **half width**: one 8×16 cell, two tiles, advancing one column, so
  Latin letters and digits mixed into a Chinese line stay readable instead of being
  stretched over a square. The font PNG is then a plain TallTextPlugin font (128px wide,
  8×16 cells, 16 characters per row).

  Turning off **Half-width single-byte characters** makes them full width instead: the
  font PNG becomes 256px wide with 16×16 cells.

Either way the font compiler's automatic recode table is positional
(`table[32 + imageTilePos]` = deduplicated tile index), so the renderer finds every
quarter arithmetically and tile deduplication is resolved by the table itself — no `.json`
`table` block needed.

### The two-byte encoding

Wide characters reach the engine as two bytes written by the **`mapping` block of the font
asset's `.json`**, which GB Studio applies when it compiles your text:

```
lead  = 0x80 + (glyph index >> 7)
trail = 0x80 + (glyph index & 0x7F)
```

Glyph indices span **0–16383**, and neither byte can ever collide with a control code or
with ASCII. `src/GlyphTextPlugin/tools/make_glyph_sheets.js` generates the sheets and that mapping together,
so you never write it by hand.

### The character tile cache

Rendered quads are allocated from a reserved range of VRAM tiles and kept in a **cache
keyed by character code** — each entry owns one quad. Repeated characters reuse their quad
instead of consuming new tiles; when the range is full, the least recently used
character's quad is evicted.

The cache can be turned off entirely with the **Enable character tile cache** engine
setting. Its bookkeeping is then compiled out and each character is rendered into the next
quad of the reserved range, cycling round-robin. Repeated characters no longer share a
quad, so the range has to be big enough for every character on screen at once.

### Variable width (VWF)

By default every wide character occupies a full 16px square, because that is what
lets the renderer hand out whole tiles. Turn on **Variable width glyphs (VWF)** and
each character instead advances by its own width, so a 12px font really takes 12px
and proportional Latin closes up:

| | Characters per 20-column line |
|---|---|
| fixed 16px | 10 |
| VWF, 12px font | 13 |
| VWF, 12px with proportional Latin | ~17 |

Text is then composed a pixel at a time into 8px screen columns: a glyph is shifted
to wherever the pen happens to be, OR-ed into the column being built, and spills into
the next one. When the pen passes the end of a column that column is finished and
becomes a pair of VRAM tiles.

Two things follow from that, and neither is optional:

- **The cache is gone.** A glyph's tiles depend on the pixel offset it started at, so
  the same character is different tiles in different places. The LRU is compiled out
  in this mode and its WRAM comes back.
- **Every screen column costs a tile pair.** Nothing is shared. An 18-column,
  two-line dialogue needs **72 tiles**; the default 64–191 range holds 64 columns,
  about 3.6 lines, which is enough because only two are ever visible. Widen it to
  64–255 for 96 columns if you draw more.

A **width table** supplies the advances — a tileset asset the generator writes next to
the sheets, registered once with **Glyph Text: Set Width Table**. Without one every
character falls back to its full cell and you get fixed-width spacing again.

Single-byte characters always come from the 8×16 font grid here, whatever the
half-width setting says. Glyph cells stay 2×2 tiles regardless of the font size, so a
12px font simply leaves 4px of air that the width table steps over.

### The reserved tile range

The plugin needs a block of background tile indices it can own. Scene background tilesets
fill up from 0 and GB Studio's UI sits at the top, so the default reserved range is
**64–191** (128 tiles = 32 cached characters).

The top 64 tiles are not all off limits, though — they hold four different things:

| Tiles | Contents | Reusable? |
|---|---|---|
| 192–200 | dialogue frame, 9 tiles | only if you never draw a frame |
| 201–202 | white and black fill | no — the dialogue events fill and scroll with them |
| 203 | menu cursor | only if you never open a stock menu |
| **204–255** | **the stock text buffer**, 52 tiles | **yes**, see below |

Tiles 204–255 are scratch space where GB Studio's variable-width-font renderer composes
each glyph before drawing it. **This plugin replaces that renderer**, so if all your
on-screen text goes through Glyph Text events, nothing writes there and you can extend the
range to 255 for **13 more cached characters** — raise the cache capacity to match.

Keep off them if the same screen also uses the stock **Display Dialogue**, **Display
Text** or **Menu** events; those still compose into 204–255. The buffer's location is
fixed in the engine, so it cannot be moved out of the way.

Or remove the condition entirely: turning on
[**Replace stock text rendering**](#replacing-the-stock-text-renderer) compiles that
renderer out, and nothing is left that could write there.

### Tile placement on Game Boy Color

On CGB, each tilemap cell can read its tile data from either VRAM bank, and the plugin
sets that per character cell:

- **Bank 0 only** — the default, and the only mode on DMG hardware.
- **Bank 1 only (Color)** — every glyph quad lives in bank 1, so the reserved indices stop
  competing with bank-0 scene tiles entirely.
- **Alternate bank 0/1 (Color)** — entries are spread across both banks, doubling the
  characters the range can hold.

On DMG the plugin falls back to bank 0 automatically.

---

## Project Setup

### 1. Install the plugin

Copy `src/GlyphTextPlugin` into your project's `plugins/` folder.

### 2. Generate the sheets and the font

The generator ships **inside the plugin**, so it is now sitting in your project at
`plugins/GlyphTextPlugin/tools/`. Double-click **`Make Glyph Sheets.bat`** there and give
it a font — it works out which project it belongs to from where it is installed, so that
is the only thing it needs. (Dropping a `.ttf` onto it works too, as does naming a
different project.)

It reads **every character your project's text events already use**, and writes
`assets/tilesets/cjk_0.png` (and `_1`, `_2`… as needed), `assets/fonts/cjk.png` and
`assets/fonts/cjk.json` into the project, then prints the settings and events to add.

### 3. Make the generated font the project's default font

**This step is not optional.** GB Studio encodes text with the `mapping` of the
**default** font (Settings → Default Font), *not* whatever the Set Font event selected —
`Set Font` only changes which glyphs the engine draws at runtime, never how the text was
compiled. Point Settings → Default Font at the generated font, or start each text with an
inline `!F:…!` font token selecting it.

### 4. Register the glyph sheets

Add one **Glyph Text: Set Glyph Sheet** per sheet to the first scene's **On Init**, with
the slot and first-glyph values the tool printed. Registered sheets are global and survive
scene changes, so this only has to happen once.

### 5. Reset the cache in every scene

Add **Glyph Text: Reset Tile Cache** to each scene's **On Init**. Loading a scene
overwrites VRAM, and there is no automatic hook for scene loads.

### 6. Draw

Use the draw events for instant text, typed-out text, or a full dialogue box.

---

## The Generator Tool

**`src/GlyphTextPlugin/tools/Make Glyph Sheets.bat`** is the front door: double-click it and it asks for the
font and the project, or drop files onto it —

```
"Make Glyph Sheets.bat" VonwaonBitmap-16px.ttf C:\Games\MyGame
```

It forwards anything else to `src/GlyphTextPlugin/tools/make_glyph_sheets.js`, which also runs on its own:

```bash
node src/GlyphTextPlugin/tools/make_glyph_sheets.js --font pixelfont.ttf --project path/to/myGame --name cjk
```

```
Glyph source (one required):
  --font <file>           a .ttf/.otf/.ttc file
  --system-font <name>    an installed font, by family name (Windows)
  --hex <file>            a GNU Unifont style .hex file

Characters (one required):
  --project <dir>         a GB Studio project folder; every character used by a
                          text event anywhere in it is collected
  --chars <file>          a text file
  --text "<string>"       characters given inline

Output:
  --out <dir>             GB Studio project folder (default: --project, else .)
  --name <prefix>         asset base name, and the name of this font set
                          (default: cjk). A different name adds an alternate
                          font -- see below.
  --font-name <text>      display name of the font in GB Studio (default: --name)
  --size <n>              pixel size / bitmap strike to use (default: 16)
  --offset-x <n>          nudge rasterised glyphs horizontally, after the fit
  --offset-y <n>          nudge rasterised glyphs vertically, likewise
  --no-fit                keep whatever the rasteriser puts at the origin
  --cols <n>              glyphs per sheet row, power of two (default: 16)
  --per-sheet <n>         glyphs per sheet, multiple of cols (default: 192)
  --first-glyph <n>       pin the first glyph index instead of allocating one
  --first-slot <n>        pin the first sheet slot instead of allocating one
  --full-width-ascii      ASCII font uses 16x16 cells instead of 8x16
  --bold                  smear every glyph a pixel right, for a bitmap bold
  --vwf                   build for variable-width rendering: pack glyphs left
                          and write a width table beside the sheets
  --space-width <n>       pen advance for a space, in pixels (default 4, 1-16).
                          Variable width only, and only on the set owning glyph 0
  --no-font               keep your own font PNG; only rewrite <name>.json
  --wizard                ask for anything not given on the command line
  --help
```

There are no dependencies: PNGs are written with node's own zlib and `.ttf` files are
parsed directly.

### Fitting glyphs to the cell

Fonts do not agree on where a glyph sits relative to the drawing origin. Galmuri14
starts a pixel in from the left and sets its baseline low enough that capitals reach
one row past a 16px cell — drawn naively, every character loses its bottom row and
the full stop disappears entirely.

So the generator rasterises into a padded canvas, measures where the ink actually
landed across the whole set, and shifts it as a group to sit inside the cell. One
shift for everything, never per glyph: a per-glyph fit would make the baseline wander
from character to character.

It moves things only as far as they need moving. A font already sitting inside its
cell is left exactly where it was, keeping the leading it was designed with — the
16px examples regenerate byte for byte after this was added.

When a font is simply larger than the cell no shift can help, and it says so:

```
warning: this font is bigger than the cell at --size 14 -- 5px too wide after
         fitting, so the edges are clipped. Lower --size, or accept it if only
         a few glyphs reach that far.
```

That is what `--full-width-ascii` is for when a font's Latin is too wide for the 8px
half-width cell, as Galmuri14's is at 14px. `--offset-x` / `--offset-y` nudge on top
of the fit, and `--no-fit` turns it off. `GTX_DEBUG=1` prints the measured box and the
shift applied.

### How fonts are read

Pixel fonts ship in two shapes, and `--font` handles both:

- **Embedded bitmap strikes** (`EBLC`/`EBDT`) are read **straight out of the file**, so
  you get exactly the pixels the designer drew — no rasteriser, no hinting, no platform
  dependency. Some of these fonts have no outlines at all (ark-pixel's `.bitmap.ttf`
  builds have an empty `glyf` table) and *cannot* be rendered by Windows at all; this is
  the only way to use them.
- **Outline fonts** are rasterised through .NET `System.Drawing` at exactly `--size`
  pixels with grid-fitting and no anti-aliasing. Windows only.

Fonts that work well at 16px: [Vonwaon Bitmap](https://timothyqiu.itch.io/vonwaon-bitmap)
(CC0, full Chinese), [Ark Pixel](https://ark-pixel-font.takwolf.com/) (OFL, CJK),
[GNU Unifont](https://unifoundry.com/unifont/) via `--hex`, or the installed *SimSun* /
*MS Gothic* / *Batang* via `--system-font`.

### Alternate fonts

A project can hold several font sets side by side — a normal one and, say, a bold or
decorative alternate that text switches to mid-sentence. Give the second set its own
`--name`:

```bash
node src/GlyphTextPlugin/tools/make_glyph_sheets.js --font bold.ttf --project MyGame --name bold --font-name "Bold CJK"
```

`--name` is the file prefix *and* the identity of the set; `--font-name` is only what GB
Studio shows in the font picker, so you can keep short file names and readable labels.

Wide glyph indices and sheet slots are **global to the plugin**, so two sets must not
overlap in either. The tool handles that itself: each set leaves a small
`<name>.glyphs.json` manifest next to its font, a new set is placed after everything
already registered, and regenerating a set in place keeps its own position so the others
never shift. Overlaps are refused with an error rather than written out. `--first-glyph` /
`--first-slot` override the placement when you want to lay it out by hand.

The report tells you which case you are in. For an alternate set it prints the `!F:…!`
token that switches to it inside a text event, instead of telling you to make it the
default font — only one font can be the default, and that is the one whose mapping GB
Studio uses for text with no font token in it.

Two things to keep in mind: every set needs its **own sheet slots** (raise *Glyph sheet
slots* to cover them all), and all sets share the **one tile cache**, so widen the reserved
tile range if two fonts are on screen at once.

### Building for variable width

Add `--vwf`. Glyphs are then packed to the left of their cell instead of centred, and
a width table is written beside the sheets:

```bash
node src/GlyphTextPlugin/tools/make_glyph_sheets.js --font ark-pixel-12px-proportional.ttf \
     --size 12 --vwf --project MyGame
```

`--size` is the size the glyphs are *drawn* at, not the cell: cells stay 2×2 tiles
either way, so a 12px font leaves air the width table steps over.

Advances come from the font when it states them (a bitmap strike carries a real
`horiAdvance`) and are measured from the ink plus a pixel of air when it does not —
which is the case for every rasterised outline font. A font that carries bitmaps for
only part of its repertoire is handled too: SimSun has 12px CJK strikes but leaves
Latin to its outlines, so the missing glyphs are rasterised and the rest read straight
out of the strike.

**The space is the one advance that cannot be measured** — a blank glyph has no ink, so
there is nothing to read a width from, and a font that states advances in a bitmap strike
often gives its space a value drawn for a much larger cell. `--space-width` states it
outright instead; it defaults to **4px**, which reads well at 12px. Zero is rejected
rather than quietly rounded: the width table uses 0 to mean "no entry", so the engine
would fall back to its own default instead of giving you a zero-width space.

The table is shared by every font set in the project and is rebuilt from all of their
manifests on each run, so adding a bold alternate does not invalidate it. Its ASCII
block comes from whichever set owns glyph 0 — an alternate font with different Latin
widths will use the primary's spacing for single-byte characters, `--space-width`
included. Passing it to an alternate set warns and does nothing.

### Rerunning it

Characters are sorted by codepoint and numbered from `--first-glyph`, so adding a line of
dialogue and regenerating **renumbers every glyph**. The tool is built around that:

- The `.gbsres` sidecars are written alongside each PNG, keeping the id and symbol of any
  that already exist — so a sheet that changed size updates itself in the editor without
  breaking the scene references or your Default Font setting. (`--font-name` does rename
  the font, which is safe: references go by id.)
- `mapping` in the `.json` is **replaced**, never merged. A leftover entry from an earlier
  run would still parse but quietly point at some other character's bitmap.
- Only the number of *sheets* can change what you have to touch by hand: if a run reports
  more sheets than before, add the extra Set Glyph Sheet events. The first-glyph values it
  prints are always current.

Characters the font does not cover are listed and left blank rather than silently skipped.

---

## Engine Settings

Found under **Settings → Glyph Text**.

| Setting | Default | Description |
|---|---|---|
| **First VRAM tile reserved for 16x16 text** | 64 | First background tile index reserved for glyph quads. |
| **Last VRAM tile reserved for 16x16 text** | 191 | Last reserved tile index, inclusive. |
| **Tile placement (VRAM bank)** | Bank 0 only | Which VRAM tile data bank glyph quads go to. |
| **Variable width glyphs (VWF)** | Off | Advance each character by its own width instead of a full cell. Compiles the cache out; needs a width table. |
| **Half-width single-byte characters** | On | ASCII is 8×16 and advances one column. Off makes it 16×16. Ignored under VWF. |
| **Enable character tile cache** | On | Keeps rendered quads in an LRU cache so repeated characters reuse them. |
| **Character cache capacity (entries)** | 32 | How many characters the cache can track, 4–128. 4 bytes of WRAM each. |
| **Glyph sheet slots** | 4 | How many sheets can be registered at once. 7 bytes of WRAM each. |
| **Glyph sheet columns** | 16 | Characters per sheet image row. Must match what the tool generated. |
| **Wide character lead byte** | 128 | Lowest byte value that starts a two-byte code. |
| **Replace stock text rendering** | Off | Compiles GB Studio's own text renderer out and points the stock *Display Dialogue*, *Display Text* and *Menu* events at this plugin instead. Frees 1,629 B of ROM (1,965 B in Color mode) and tiles 204–255. [See below](#replacing-the-stock-text-renderer). |
| **Menu cursor row** | Lower tile of the line | Which tile of a two-row menu line the cursor sits on. Lower is level with the baseline, upper reads as slightly raised. |

Usable cache entries are `min(cache capacity, range size / 4)` — or
`min(cache capacity, range size / 2)` with *Alternate bank 0/1*. With the cache disabled
the capacity setting drops out and the whole reserved range is used.

---

## Size Limits and Restrictions

- **A sheet must fit in one ROM bank**: 256 characters (1024 tiles, 16 KB). The tool
  defaults to 192 per sheet to leave the bank some slack. Split larger scripts over
  several sheets and raise **Glyph sheet slots**.
- **Glyph indices stop at 16383** — about 16 000 characters, far past what a Game Boy ROM
  can hold anyway.
- **The reserved range must not collide** with your scene background tiles (0 upward), the
  dialogue frame and fills (192–202) or the menu cursor (203). Tiles **204–255 are fair
  game** when nothing on screen uses the stock text renderer — see
  [The reserved tile range](#the-reserved-tile-range).
- **The cache can overflow.** When it is full, the least recently used character's quad is
  reused, so text drawn long ago can visually corrupt if it is still on screen while a lot
  of new text is drawn. Reserve at least 4 tiles per character visible at once.
- **Reset the cache on every scene load** — there is no automatic hook for it. *Reset Tile
  Cache* also rewinds the round-robin cursor when the cache is disabled, so keep calling it
  either way.
- **Fonts can be switched mid-text.** Cache entries for single-byte characters are keyed
  by font as well as by character, so two fonts' glyphs live in the cache side by side and
  a `\002` switch costs nothing — but each font in play holds its own entries, so give the
  reserved range room for both.
- **Under VWF, plan the tile range around columns, not characters** — a tile pair per
  8px of line, so roughly 72 tiles for a two-line dialogue. Running short does not
  fail, it recycles: the oldest columns are reused and text still on screen corrupts.
- **Text length**: the engine's text buffer is 255 bytes and a wide character costs two of
  them, so roughly **120 characters per text event**.
- **Line width**: a wide character is 2 tiles, so **10 per screen line**, or **9** inside a
  framed dialogue box. A dialogue defaults to min height 6, max height 8, scroll height 4 —
  two visible lines. The script editor's own preview still counts in 8px cells, so its
  wrapping hints do not apply.
- **A character with no sheet covering it draws as a blank square**, not garbage.
- **Avatars and the `\007` text colour code are not supported.** The rest of the stock
  control-code set is handled (speed, font switch, gotoxy, wait-for-input, palette);
  `\010` direction is skipped, since rendering is left-to-right only.
- Compatible variants are included for use alongside **ContinuousScenePlugin** and
  **ScreenScrollPlugin**, and are selected automatically.

### Replacing the stock text renderer

GB Studio's own renderer normally sits in the ROM alongside this plugin's, even in a
project where every visible string is drawn by the plugin. **Replace stock text
rendering** removes it.

With the setting on, the plugin ships a copy of the engine's `ui.c` whose text renderer
is compiled out, and supplies `ui_draw_text_buffer_char` itself. Nothing calls the plugin
explicitly — the stock engine's own `ui_update()` resolves to it, so everything that used
to draw stock text now draws glyphs:

| | |
|---|---|
| **Display Dialogue**, **Display Text** | render as 16×16 glyphs, without swapping in this plugin's events |
| **Menu** | renders as glyphs, with the cursor rows corrected — see below |

Two things you get back:

- **1,629 bytes of ROM** (**1,965** in a Color build), measured on the module, minus 8
  bytes for the forwarder. Plus 5 bytes of WRAM.
- **Tiles 204–255.** They were the stock renderer's scratch buffer, which is why
  [the reserved range](#the-reserved-tile-range) only claims them on the condition that
  nothing on screen uses stock text. With the stock renderer gone there is nothing left
  to collide with, and that condition disappears.

**Menus work with or without the setting.** Two things are wrong with the stock Menu
event once lines are two rows tall: its cursor steps one 8px row per option, falling a
row further behind each time, and its window is sized at compile time for stock rows so
the frame comes out half as tall as the text in it.

The driver lives in this plugin as **`<prefix>_ui_run_menu`**, a copy of the stock one
with the cursor stride as a parameter. Option *n* occupies rows `(n-1)*stride + 1` through
`+ stride`, and which of them the cursor takes is the
**Menu cursor row** setting: the lower tile sits level with the baseline, the upper one
reads as slightly raised, and which suits depends on where your font puts its glyphs in
the cell. At stride 1 there is only one row and both choices are the stock position. It is always compiled, under its own name, so:

| | Menu driver used |
|---|---|
| this plugin’s **Menu** event | calls `<prefix>_ui_run_menu` directly, through a native |
| stock **Menu** event, setting off | stock `ui_run_menu`, unchanged and still correct for stock text |
| stock **Menu** event, setting on | `ui_run_menu` is rewired to `<prefix>_ui_run_menu` |

The event calls the native rather than emitting `VM_CHOICE`, because that instruction
always calls `ui_run_menu` — which is only this plugin’s when the setting is on. Going
direct is what lets the event work either way. It also means no `.MENUITEM` table is
emitted: the options are a single column, so the driver lays them out itself.

With the setting off, the bundled `ui.c` is the engine's own file byte for byte, so it
costs nothing and changes nothing — verified by stripping the guards and comparing. It
does mean this plugin now overrides `ui.c`, so it cannot be combined with another plugin
that overrides the same file unless one of them ships an `engineAlt` variant for the
other; the ContinuousScene and ScreenScroll variants shipped here already do.

---

## Events Reference

All events appear under the **Dialogue** group in the script editor.

| Event | Description |
|---|---|
| **Glyph Text: Display Dialogue** | A stock-style dialogue window where every line is two tiles tall. |
| **Glyph Text: Draw To Background** | Instantly draws text at an X/Y tile position on the background layer. |
| **Glyph Text: Draw To Overlay** | The same, on the overlay (window) layer. |
| **Glyph Text: Draw At Text Speed** | Types the text out at the current text speed on either layer. Blocks until done. |
| **Glyph Text: Reset Tile Cache** | Forgets all cached glyph quads. Call this in each scene's On Init. |
| **Glyph Text: Set Tile Range** | Changes the reserved VRAM tile range and tile placement at runtime. |
| **Glyph Text: Set Glyph Sheet** | Points a sheet slot at a tileset asset covering a run of glyph indices. |
| **Glyph Text: Set Width Table** | Registers the table of advances that variable-width mode needs. |
| **Glyph Text: Menu** | A menu sized and stepped for two-row lines, drawn with this plugin. Works with or without *Replace stock text rendering*. |

---

## Media

Four mono-mode example projects. Each holds its own generated sheet, font and mapping,
and each `script.txt` mirrors its text for reference.

All four are the same scenes in different languages — a background draw, a typewriter
pass and a scrolling dialogue.

| Example | Script | Mode | Glyphs from |
|---|---|---|---|
| `ChineseGlyphTextPluginExample/` | 简体中文 | fixed 16px | [Vonwaon Bitmap 16px](https://timothyqiu.itch.io/vonwaon-bitmap) — Haoyu Qiu, **CC0** |
| `JapaneseGlyphTextPluginExample/` | 日本語 (kana + kanji) | fixed 16px | the same Vonwaon Bitmap 16px, **twice** — see below |
| `KoreanGlyphTextPluginExample/` | 한글 | **variable width, 12px** | [Galmuri11](https://galmuri.quiple.dev/) — **OFL** |

`MultiLanguageGlyphTextPluginExample/` is the other **variable-width** one: six screens
plus a mixed dialogue, at 12px, from
[Ark Pixel 12px proportional](https://ark-pixel-font.takwolf.com/) (OFL) — with Korean
supplied by a **second font set**, since ark-pixel carries no hangul.

| Screen | Shows | Font set |
|---|---|---|
| Latin | `iiiii vs WWWWW` and `.,;:!? 0123456789` — the advances really differ | `cjk` |
| 简体中文 | CJK at exactly 12px | `cjk` |
| 日本語 | kana and kanji | `cjk` |
| Русский | Cyrillic, proportional | `cjk` |
| Ελληνικά | Greek, proportional | `cjk` |
| 한글 | hangul, from an alternate font | `korean` |
| Dialogue | all of them in one text, switching font mid-line for 한국어 | both |
| Menu | three options, each drawn at its own width | `cjk` |

The density is the point: *Пропорциональный* is 16 characters in **13 screen columns**
(104px), where fixed-width 16px rendering would need 32. It ships with the reserved range
at 64–192, which gives 64 columns against a worst-case screen of 56 — VWF spends a tile
pair per column, so widen it towards 255 if you write longer text.

The `.ttf` files these were generated from are committed in [`fonts/`](fonts/), with
their licences, so the examples rebuild from this repository alone. Run from the
repository root:

```bash
node src/GlyphTextPlugin/tools/make_glyph_sheets.js --font fonts/VonwaonBitmap-16px.ttf --project ChineseGlyphTextPluginExample
node src/GlyphTextPlugin/tools/make_glyph_sheets.js --font fonts/VonwaonBitmap-16px.ttf --project JapaneseGlyphTextPluginExample --name cjk
node src/GlyphTextPlugin/tools/make_glyph_sheets.js --font fonts/VonwaonBitmap-16px.ttf --bold --out JapaneseGlyphTextPluginExample      --text "太字出ます。プラグイン切替" --name bold
node src/GlyphTextPlugin/tools/make_glyph_sheets.js --font fonts/Galmuri11.ttf --size 12 --vwf \
     --project KoreanGlyphTextPluginExample --font-name "Galmuri11"
node src/GlyphTextPlugin/tools/make_glyph_sheets.js --font fonts/Galmuri11.ttf --size 12 --vwf \
     --out MultiLanguageGlyphTextPluginExample --name korean --font-name "Galmuri11 Korean" \
     --text "글리프 문자 표시 가변 폭 한글 렌더링 열두 픽셀 크기 를 누르세요 한국어"
node src/GlyphTextPlugin/tools/make_glyph_sheets.js --font fonts/ark-pixel-12px-proportional-zh_cn.ttf \
     --size 12 --vwf --out MultiLanguageGlyphTextPluginExample --name cjk \
     --chars MultiLanguageGlyphTextPluginExample/chars_cjk.txt --font-name "Ark Pixel 12px"
```

**The order of the last two matters**, and the primary set cannot use `--project`.

The width table is project-wide — every run rebuilds it from *all* of the manifests but
writes it as `<name>_widths.png` — so whichever set is generated **last** owns the
complete copy, and that is the one to register. Here that is `cjk`, so the scene keeps
registering `cjk_widths` and the duplicate `korean_widths.png` is deleted.

`--project` is **font-blind**: it sweeps every string in the project, with no idea which
ones are tagged to another font. Once the Korean screen existed, regenerating `cjk` from
`--project` pulled all 27 hangul into the ark-pixel set — which carries none of them —
and the set grew until it collided with `korean`'s indices:

```
error: glyph indices 0-127 of "cjk" overlap "korean" (112-143).
```

Hence `chars_cjk.txt`, holding just the characters not tagged to the Korean font. Any
project mixing a script its main font cannot draw needs the same split.

Every example ends with a **menu**, built from the plugin’s own Menu event: a window
sized for two-row lines, a cursor that steps to match, and the chosen option left in the
`Item_Id` variable (zero if B cancelled it).

All four examples are redistributable: every one is generated from an OFL or CC0 font,
and [`fonts/`](fonts/) carries each licence next to the file it covers.

The Korean examples store Galmuri's **precomposed syllables** — one glyph per syllable,
exactly what the designer drew. At 43 syllables that is 2,752 bytes. A script whose
syllable count runs into the hundreds is what would strain this, since hangul has 11,172
of them in total; authored dialogue never comes close.

The Japanese text avoids 枠 and 閉, which Vonwaon does not carry — a good illustration of
the tool's missing-character report. Note that the ark-pixel `-ja` / `-ko` *monospaced*
builds are a ~3,200-codepoint subset with **no hangul at all**, whatever their language
suffix suggests — which is exactly why the MultiLanguage example needs a second font set
for its Korean screen.

---

## Memory Footprint

Measured from the plugin's own module in a DMG build of `ChineseGlyphTextPluginExample`
(GB Studio 4.3.0-e1, default engine settings: 32 cache entries, 4 sheet slots).

| | Cost |
|---|---|
| Bank 0 (HOME) | 0 bytes |
| WRAM | 176 bytes |
| Banked ROM | 2,889 bytes |

- **WRAM** scales with two settings: **4 bytes per cache entry** (128 of the 176 at the
  default 32 entries) and **7 bytes per glyph sheet slot** (28 at the default 4). Turning
  the cache off reclaims the LRU tables entirely.
- **ROM** above is the renderer only. Glyph sheets cost **64 bytes per character** on top
  of it — a 500-character script is about 32 KB, two ROM banks.
- **SRAM**: not used.

## Changelog

Grouped by the date each change was merged into the official
[gb-studio-plugins](https://github.com/gb-studio-dev/gb-studio-plugins) repository.

Only bug fixes, new features and feature changes are listed. Engine version
bumps, patch regeneration, packaging fixes and documentation edits are omitted.

### 2026-08-08

- Initial release: CJK 2x2-tile-quad text, with glyph sheets supplied as tileset assets and an optional LRU cache.
- Menu support and a "replace stock UI" engine setting.

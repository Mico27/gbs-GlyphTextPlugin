# Source fonts

The `.ttf` files the four example projects were generated from, so the examples can be
rebuilt from this repository alone. Nothing here ships in a ROM — the generator reads
these and writes the glyph sheets, font PNG and mapping into a project's `assets/`.

| Font | Used by | Licence |
|---|---|---|
| `VonwaonBitmap-16px.ttf` | Chinese and Japanese examples (both fonts of the Japanese one — the bold is `--bold`, not a second file) | **CC0** — [Vonwaon Bitmap](https://timothyqiu.itch.io/vonwaon-bitmap), Haoyu Qiu ([`VonwaonBitmap-LICENSE.txt`](VonwaonBitmap-LICENSE.txt)) |
| `Galmuri11.ttf` | Korean example, and the `korean` set of the MultiLanguage example | **OFL 1.1** — [Galmuri](https://galmuri.quiple.dev/), Lee Minseo ([`Galmuri-OFL.txt`](Galmuri-OFL.txt)) |
| `ark-pixel-12px-proportional-zh_cn.ttf` | MultiLanguage example, primary set | **OFL 1.1** — [Ark Pixel Font](https://ark-pixel-font.takwolf.com/), TakWolf ([`ark-pixel-OFL.txt`](ark-pixel-OFL.txt)) |

Both OFL fonts keep their licence text alongside them, as the licence requires of anyone
redistributing them. All three are redistributable, which is why the examples use them.

The exact commands that produced each example's assets are in the
[main README](../README.md#media), and run from the repository root against these paths.
Regenerating with them reproduces what is committed byte for byte.

## Notes on these particular files

**Vonwaon** is an outline font with a real `glyf` table, so it is rasterised through
GDI+. It covers Chinese, kana and most kanji, but **not 枠 or 閉**, and no hangul.

**Galmuri11** carries an 11px embedded bitmap strike, read directly rather than
rasterised. It has all 11,172 precomposed hangul syllables. The examples draw it at
`--size 12`; `Galmuri14.ttf` exists upstream for 14px, but the Korean example moved to
12px variable width.

**Ark Pixel 12px proportional** is `zh_cn` because all seven language variants share one
24,433-codepoint cmap and differ only in glyph forms — and **none of them contains
hangul**, whatever the `-ko` suffix suggests. That is exactly why the MultiLanguage
example needs Galmuri as a second font set for its Korean screen.

Ark Pixel is also published as `.woff2`; do not use that build. Its `glyf` table is
transformed, which cannot be read without a full WOFF2 reconstruction. Take the
`-ttf` or `-otf` download.

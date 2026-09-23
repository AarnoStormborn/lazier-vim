# Rendering Markdown inside Neovim — research & options

**Question:** can we build a markdown renderer inside Neovim, and if so, what are the
options?

**Verdict:** yes — several mature, actively maintained ways. Neovim itself has **no
built-in WYSIWYG markdown renderer** (as of 0.12 it only *enables treesitter
highlighting for markdown files by default*), but the editor exposes exactly the
primitives a renderer needs (treesitter + conceal + extmarks/virtual text), and that
is what the plugins below use. This repo **already ships two of them** via the
LazyVim `lang.markdown` extra:

- **`render-markdown.nvim`** — renders markdown *in the buffer* (headings, code,
  tables, quotes, checkboxes, LaTeX…). Toggle with `<leader>um`.
- **`markdown-preview.nvim`** — renders in a **real browser** with scroll sync,
  KaTeX, Mermaid, PlantUML. Toggle with `<leader>cp`.

So the practical answer is: you don't need to build one — you need to choose which
layer(s) you want and turn them on.

---

## 1. What "render markdown in nvim" can mean

There are four distinct layers. Most setups mix several; they don't conflict unless
two plugins render *inside the same buffer*.

| Layer | What it does | Runs where |
|---|---|---|
| **A. In-buffer rendering** | Hides/conceals source, draws headings, tables, code blocks, quotes with extmarks/virtual text | Inside Neovim, same buffer |
| **B. Browser/HTML preview** | Opens the file in a browser/webview with real CSS, KaTeX, Mermaid | Separate app window |
| **C. Terminal preview** | Renders markdown to ANSI in a float/split/pager | Inside Neovim (`:terminal`) |
| **D. Media in-buffer** | Inline images, math images, diagrams via terminal graphics protocol | Inside Neovim, needs terminal support |
| **E. Authoring support** (orthogonal) | LSP, linting, formatting, TOC, folding, navigation | Inside Neovim, no rendering |

---

## 2. What this repo already has (verified)

Evidence gathered from the live symlinked config in this repo:

| Piece | Status | Evidence |
|---|---|---|
| LazyVim `lang.markdown` extra | **enabled** | `lazyvim.json` lists `lazyvim.plugins.extras.lang.markdown` |
| `render-markdown.nvim` | **installed**, v8.13.0 (2026-06-18) | `~/.local/share/nvim/lazy/render-markdown.nvim`; `require("render-markdown")` OK |
| In-buffer render actually runs | **yes** on nvim 0.12.2, no errors | headless: `require("render-markdown").get() == true` |
| `markdown-preview.nvim` | **installed**, prebuilt `markdown-preview-macos-arm64` binary | `~/.local/share/nvim/lazy/markdown-preview.nvim/app/bin/`; `:MarkdownPreviewToggle` exists |
| Treesitter parsers | `markdown`, `markdown_inline`, `html`, `yaml` present | `~/.local/share/nvim/site/parser/*.so` |
| `latex` treesitter parser | **missing** (only needed for in-buffer LaTeX formulas) | not in `site/parser` |
| `marksman` LSP | configured by the extra | `LazyVim/lang/markdown.lua` sets `servers.marksman` |
| Formatters/linters | prettier, markdownlint-cli2, markdown-toc | extra config + `mason` ensure_installed |
| `snacks.nvim` | installed, but **`image` module not enabled** | `lua/plugins/snacks.lua` only configures `picker` |
| `glow` CLI | installed | `/opt/homebrew/bin/glow` |

Installed keymaps from the extra:

- `<leader>um` — toggle render-markdown (`Snacks.toggle`)
- `<leader>cp` — `:MarkdownPreviewToggle` (browser preview)

> Note: render-markdown's own config here is the LazyVim default (`width = "block"`,
> signs/icons off, checkboxes off). See §7 for what to change.

---

## 3. Layer A — in-buffer rendering (the "inside nvim" answer)

These hide the markdown source and draw a styled view in the same buffer.

| Plugin | Maintained | Requirements | Strengths | Notes |
|---|---|---|---|---|
| **`MeanderingProgrammer/render-markdown.nvim`** | yes, very active | nvim ≥0.9 (rec. ≥0.10), TS `markdown` + `markdown_inline` | Fast, stable, modal raw↔rendered, HTML comments, LaTeX blocks, tables, callouts, custom handlers; only renders visible range | **Already installed here.** Needs `latex` TS parser + `pylatexenc` for formula rendering. Docs: `doc/purpose.md`, `doc/limitations.md` |
| **`OXY2DEV/markview.nvim`** | yes, very active | nvim ≥0.10.3 | More document types (markdown, HTML, LaTeX, Typst, YAML, Asciidoc), **hybrid mode** (render while editing), **splitview** (source+preview side by side), wrap support | The main alternative. Clashes with render-markdown — pick **one** |
| **`lukas-reineke/headlines.nvim`** | yes | nvim + TS | Background highlight bars for headings (markdown/org/neorg), cheap and simple | Disappears while editing; clashes if combined with the two above |
| **`obsidian-nvim/obsidian.nvim`** (formerly `epwalsh/obsidian.nvim`) | yes | nvim ≥0.10 | Obsidian PKM (links, backlinks, daily notes) **plus** a UI that renders notes | Its UI clashes with render-markdown; disable one if combining |
| `preservim/vim-markdown`, `tpope/vim-markdown` | legacy | Vim | Syntax/conceal via classic syntax, not treesitter | Superseded by TS + render-markdown |

**Choose between render-markdown and markview:** they solve the same problem with
different aesthetics. render-markdown is lighter and "disappears in insert mode";
markview is more configurable and adds hybrid/splitview. Both are good; running both
is not.

---

## 4. Layer B — browser / HTML preview (highest fidelity)

| Plugin | Backend | Math / diagrams | Requirements | Status |
|---|---|---|---|---|
| **`iamcco/markdown-preview.nvim`** | local Node server + browser, scroll sync | KaTeX, Mermaid, PlantUML, Chart.js, flowchart, TOC, local images | Node **or** prebuilt binary | **Installed here** (`<leader>cp`). Development is slow (last release ~2022); community forks exist (e.g. `selimacerbas/markdown-preview.nvim` adds newer Mermaid) |
| **`toppair/peek.nvim`** | Deno + native **webview** window (or browser) | KaTeX, Mermaid | **Deno** (not installed here) | Modern, live update, github-style look, sync scroll |
| **`ellisonleao/glow.nvim`** | wraps the `glow` CLI, float window | — | `glow` (installed here) | **Archived** — author points to render-markdown |
| `euclio/vim-markdown-composer` | Rust server + browser | — | Rust | Older |

Browser preview is the only layer that gives **full CommonMark fidelity**: real
tables, KaTeX math, Mermaid diagrams, images, CSS. It's a second window, not
in-buffer. markdown-preview.nvim is already wired up; peek.nvim is the modern
replacement if you're willing to install Deno.

---

## 5. Layer C — terminal renderers (ANSI in a float/split)

Useful if you want a "read mode" without leaving the terminal.

- **`glow`** (CLI, installed) — `glow file.md` in a `:terminal`; `glow.nvim` wraps it
  into `:Glow` (archived, still works).
- **`mdcat`** — best-in-class ANSI renderer: tables (limited: no wrapping, inline
  markup stripped), code highlighting, images, **Mermaid** (via the headless Rust
  `merman` engine), and math (RaTeX). Mermaid/math render as PNG on
  kitty/iTerm2/WezTerm/Ghostty and as **Unicode otherwise**. ⚠️ Its Homebrew build
  currently fails in this environment (`llvm@22` patch checksum mismatch).
- **`bat` / `rich-cli` / `ov`** — pagers with markdown highlighting/rendering.

These are thin wrappers; the tradeoff is no in-buffer editing and weaker layout.

---

## 6. Layer D — inline images, math, diagrams (kitty graphics)

This is the layer that depends on your terminal, not Neovim.

| Plugin | Protocol / backend | Inline images in markdown | Math | Diagrams |
|---|---|---|---|---|
| **`folke/snacks.nvim` `image` module** | Kitty Graphics Protocol, tmux passthrough, ImageMagick for conversion | **yes** (markdown, html, norg, latex, typst, tsx/js/css/vue/svelte/scss) | **LaTeX/Typst math** compiled to an image | **Mermaid** via `mmdc` → image |
| **`3rd/image.nvim`** | Kitty graphics / ueberzugpp / sixel | yes (markdown, neorg integrations) | via latex.nvim integration | — |
| **`ryleelyman/latex.nvim`** | treesitter-based, minimal | — | inline math in markdown & LaTeX | — |
| **`jbyuki/nabla.nvim`** | virtual text / images | — | inline math preview | — |
| **`lervag/vimtex`** | full LaTeX toolchain | — | full LaTeX authoring | — |

**snacks.image is the best fit here** because `snacks.nvim` is already installed;
it's just disabled. Requirements: a kitty-graphics-capable terminal +
ImageMagick (and `mmdc`/Mermaid CLI only if you want diagrams). Check health with
`:checkhealth snacks`.

Terminal support (from `snacks.nvim` docs):

| Environment | Inline images |
|---|---|
| **kitty** (direct) | ✅ best support |
| **kitty inside herdr** | ✅ — herdr forwards the kitty graphics protocol; depends on the outer terminal |
| **kitty inside tmux** | ⚠️ needs `set -gq allow-passthrough on` (tmux ≥3.3); snacks tries to enable it, but passthrough can be flaky |
| **Warp** (direct or in a multiplexer) | ⚠️ Warp advertises kitty-graphics support, but terminal apps have reported images not rendering — verify with `:checkhealth snacks` |
| Ghostty | ✅ |
| WezTerm | ⚠️ partial — inline images not supported |
| zellij | ❌ no passthrough support |

Given your setup (**kitty, sometimes Warp, inside tmux or herdr**): inline
images/math will work best in **kitty + herdr** or plain kitty; expect friction in
**tmux** (passthrough) and **Warp**.

---

## 7. Layer E — authoring support (orthogonal, safe to combine)

None of these render, so they stack with layer A/B.

- **LSP:** `marksman` (already configured) for completion/definitions/references;
  `markdown-oxide` for Obsidian-style PKM features.
- **Lint/format:** `markdownlint-cli2`, `prettier`, `markdown-toc` (already
  configured by the extra). Run via `conform.nvim` / `nvim-lint`.
- **Editing/nav:** `tadmccorkle/markdown.nvim` (TOC, keybindings, list editing),
  `jakewvincent/mkdnflow.nvim` (folding, tables, links), `bullets.vim`
  (auto-bullets), `vim-table-mode`/`table-mode`.
- **Headings/folding:** treesitter folds + `headlines.nvim`, or
  `tadmccorkle/markdown.nvim`'s TOC/table tools.

---

## 8. Comparison at a glance

| Option | Layer | In-buffer? | Full fidelity? | Terminal deps | Already here | Effort |
|---|---|---|---|---|---|---|
| render-markdown.nvim | A | ✅ | ⚠️ good, not perfect | none (Nerd font icons) | ✅ installed | 0 |
| markview.nvim | A | ✅ | ⚠️ good + more types | none | ❌ | install + replace render-markdown |
| headlines.nvim | A | ✅ | basic | none | ❌ | small |
| markdown-preview.nvim | B | ❌ (browser) | ✅ (KaTeX/Mermaid) | Node or prebuilt | ✅ installed | 0 |
| peek.nvim | B | ❌ (webview/browser) | ✅ | Deno | ❌ | install Deno |
| glow.nvim / glow | C | float | basic | glow CLI | ✅ CLI only | tiny |
| snacks.image | D | ✅ | images/math/mermaid | kitty graphics + ImageMagick | ❌ disabled | small |
| image.nvim | D | ✅ | images | kitty/ueberzug/sixel + ImageMagick | ❌ | medium |
| **build your own** | A/D | ✅ | whatever you build | — | — | large (see §10) |

---

## 9. Recommended path for this repo

**Tier 0 — nothing to do, already works**
- `<leader>um` in a markdown file → in-buffer render.
- `<leader>cp` → browser preview with KaTeX/Mermaid.

**Tier 1 — small wins (if you want them), all config-only**
1. Install the `latex` treesitter parser and `pylatexenc` (`pipx`/`pip`) so
   render-markdown can draw LaTeX formulas in-buffer.
2. Enable `snacks.image` in `lua/plugins/snacks.lua` (`image = {}`) to get inline
   images + math in markdown (works in kitty/herdr; needs ImageMagick).
3. Tune render-markdown's LazyVim defaults if the "block" width or disabled
   checkboxes bother you (the extra sets `heading.icons = {}`, `code.sign = false`,
   `checkbox.enabled = false`).

**Tier 2 — switch/extend**
- Prefer markview's hybrid mode / splitview / multi-format support? Replace
  render-markdown with markview (don't run both).
- Want a modern webview preview? Add `peek.nvim` (requires Deno); it can coexist
  with either in-buffer renderer.
- Note-taking in a vault? Add `obsidian.nvim` / `markdown-oxide`, and disable one
  renderer's UI to avoid clashes.

**Don't build your own** unless you specifically want to learn the internals — see
below.

---

## 10. Can we build one ourselves? Yes — here's what it takes

Neovim has no built-in markdown renderer, but everything a renderer needs is
public API. A minimal "conceal + style" renderer is a few hundred lines; feature
parity with render-markdown is thousands (it ships ~100 Lua files, a test suite,
and benchmarks).

**The primitives:**

1. **Parse** — treesitter `markdown` + `markdown_inline` parsers, `vim.treesitter.get_parser`,
   `vim.treesitter.query.get`, `:InspectTree`. Neovim 0.12 enables TS highlighting
   for markdown by default, so `@markup.*` captures/highlights already exist.
2. **Hide source** — `conceallevel`/`concealcursor` + extmark `conceal = ""` (or
   treesitter `@conceal` metadata). This is how `**bold**` renders as **bold**.
3. **Draw** — `vim.api.nvim_buf_set_extmark` with:
   - `virt_text` + `virt_text_pos = "inline"|"overlay"|"eol"|"right_align"`
   - `virt_text_win_col` for column-precise backgrounds (code/heading bars)
   - `virt_lines` / `virt_lines_above` for table borders and heading rules
   - `hl_group`, `end_right_gravity`, `hl_eol`
4. **React** — `ModeChanged` / `InsertEnter`/`InsertLeave` to switch raw↔rendered
   (`concealcursor`), `TextChanged`/`BufWritePost` to re-render, and `WinScrolled`
   or a decoration provider (`on_range`, new in 0.12) to render only visible lines.
5. **Measure** — `vim.api.nvim_win_text_height` (extended in 0.12) for correct
   heights when inserting virtual lines.

**Minimal proof-of-concept (~30 lines, conceal + heading style):**

```lua
-- Drop this in a test buffer to see the mechanism render-markdown is built on.
local ns = vim.api.nvim_create_namespace("my-md-render")
local function render()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local parser = vim.treesitter.get_parser(buf, "markdown")
  local tree = parser:parse()[1]
  local q = vim.treesitter.query.get("markdown", "highlights") or vim.treesitter.query.get("markdown_inline", "highlights")
  for id, node in q:iter_captures(tree:root(), buf) do
    local name = q.captures[id]              -- e.g. "markup.heading.1"
    if name:match("^markup.heading") then
      local sr, _, er, ec = node:range()
      local mark = {
        hl_group = "Title",
        virt_lines = { { { string.rep("─", 60), "Comment" } } },
        virt_lines_above = false,
      }
      if er == sr then mark.end_col = ec end -- extmark end_col is single-line only
      vim.api.nvim_buf_set_extmark(buf, ns, sr, 0, mark)
    end
  end
  vim.wo.conceallevel = 2
  vim.wo.concealcursor = "nc"
end
vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "ModeChanged" }, { callback = render })
```

This is intentionally crude, but it demonstrates the whole trick: **parse with
treesitter → conceal the markup → draw virtual text/lines**. That is exactly how
render-markdown and markview work.

**Realistic effort estimate:**

| Goal | Effort |
|---|---|
| Conceal `**bold**`/`*italic*`/`` `code` `` + style headings | ~150–300 LOC, a weekend |
| + tables, lists, checkboxes, quotes, code-block boxes | weeks; many edge cases |
| + modal raw/rendered, visible-range rendering, LaTeX, custom handlers, tests | months; this is render-markdown |

**Recommendation:** use `render-markdown.nvim` (already installed) or
`markview.nvim`; build your own only as a learning exercise.

---

## 11. How to try the options right now

```vim
" already available in this repo
<leader>um            " toggle in-buffer render (render-markdown)
<leader>cp            " toggle browser preview (markdown-preview.nvim)

" check media/terminal support if you enable snacks.image later
:checkhealth snacks

" inspect the parse tree renderers use
:InspectTree
```

If you enable `snacks.image`, put your markdown window in **kitty (optionally via
herdr)** for inline images; in tmux add `set -gq allow-passthrough on` to tmux.conf.

---

## 12. Follow-up: engine choice for an in-terminal split preview

The goal here was narrower than §1–§11: a **side-by-side pane, inside Neovim, that
renders tables, Mermaid, and code well**, live, without the browser's one-window
limitation. Requirement-by-requirement comparison of the realistic engines,
followed by what was actually verified.

### 12.1 Requirements

In-terminal · source + preview visible at once · live update · tables · Mermaid ·
code blocks · math · images.

### 12.2 The decisive constraint: who draws the pixels?

- A CLI renderer (`glow`, `mdcat`) running **inside Neovim's `:terminal`** is inside
  a terminal emulator (libvterm), which does **not** implement the Kitty/Sixel
  graphics protocol. Child-process image/PNG output is not displayed; only the
  text/Unicode fallback survives. So a CLI pane can give you Mermaid/math as
  *Unicode text*, but not as real diagrams.
- To get **real diagram/math/image pixels inside Neovim**, Neovim itself has to emit
  the graphics escape sequences into its own UI — which is exactly what
  `snacks.image` (or `image.nvim`) does in a normal buffer.
- Therefore the only architecture that satisfies *Mermaid as an actual diagram*
  in-terminal is: **a normal markdown buffer in a split**, rendered with extmarks,
  with `snacks.image` overlaying media. That is also Neovim 0.12's forward path
  (native Kitty-graphics API landed on master).

### 12.3 Comparison

| Capability | render-markdown `:…preview` | markview splitview | mdcat in `:terminal` | glow | own Lua renderer |
|---|---|---|---|---|---|
| In-terminal | ✅ nvim buffer | ✅ nvim buffer | ⚠️ terminal buffer (ANSI) | ⚠️ float | ✅ |
| Source + preview at once | ✅ (verified) | ✅ | ✅ | ✅ | build |
| Live update | ✅ (verified) | ✅ | rerun needed | rerun | build |
| Tables | ✅ box-drawn | ✅ | ⚠️ limited | ~ | build |
| Mermaid | ✅ **PNG** via snacks.image + `mmdc` | ✅ same | ✅ **Unicode** / PNG if protocol | ❌ none | build |
| Math | ✅ **PNG** via snacks.image + tectonic | ✅ same | ✅ Unicode / PNG | ❌ none | build |
| Images | ✅ snacks.image (Kitty) | ✅ | ⚠️ PNG, but not shown inside nvim terminal | ❌ | build |
| Code blocks | ✅ boxed + TS highlight | ✅ | ✅ ANSI highlight | ✅ | build |
| External deps | `mmdc`, `tectonic`, `ghostscript`, ImageMagick, `latex` TS parser | same | `mdcat` (install broken here) | none | none |
| Effort | config + thin wrapper | swap plugin | small wrapper | tiny | large |

### 12.4 Verified in this environment

| Piece | Result |
|---|---|
| `:RenderMarkdown preview` opens a right split, source stays raw/editable, preview buffer is read-only and gets **21 render extmarks** | ✅ verified on nvim 0.12.2 |
| `render-markdown` already live-syncs the preview buffer on `TextChanged`/`CursorMoved` | ✅ read from `core/preview.lua` + reproduced |
| Mermaid → PNG: `mmdc -i x.mmd -o x.png -t dark` (`@mermaid-js/mermaid-cli` 11.17.0) | ✅ produced a 1282×392 PNG, no Chromium setup needed |
| Math → PNG: `tectonic` → PDF → Ghostscript → `magick` | ✅ produced a PNG (needed `ghostscript`, now installed) |
| `snacks.image` renders `` ```mermaid `` fences (query sets `chart.mmd` → `mmdc`) and `` ```math `` fences (`math.tex` → LaTeX), plus images | ✅ confirmed in `snacks.nvim/queries/markdown/images.scm` |
| Installed to enable the above | `tectonic`, `imagemagick`, `ghostscript`, `@mermaid-js/mermaid-cli` |
| `mdcat` via Homebrew | ❌ blocked: `llvm@22` patch checksum mismatch |

### 12.5 Recommendation

**Primary — Neovim-native pane (satisfies every requirement):**
use/reuse the extmark renderer in a split (`:RenderMarkdown preview`, or
`markview.nvim` for a different look) and enable **`snacks.image`** so Mermaid,
math, and images become real PNGs. All dependencies are installed and validated
(`mmdc`, `tectonic`, `ghostscript`, ImageMagick); only the `latex` treesitter
parser and the `snacks.image` config are still missing.

**Fallback — CLI pane (lightweight, no graphics):**
`mdcat` in a `:terminal` split with `--image-protocol=none`, giving Mermaid and
math as Unicode and code with ANSI highlight. Good for tmux/Warp where Kitty
graphics is unreliable; no Chromium/LaTeX toolchain. Blocked on a working `mdcat`
build in this environment.

**glow is out** — it cannot render Mermaid or math.

**Build vs configure:** the media requirement forces the markdown-buffer +
extmark + `snacks.image` architecture, so a from-scratch renderer only changes the
*text look*, not the media capability. A custom plugin is worth it only if the
extmark style itself is the problem — and even then, its text renderer must stay
extmark-based (not text-transforming) or media integration breaks.

### 12.6 Implemented: `mdpreview`

Option B was chosen and built: a local plugin at `lua/mdpreview/` (loaded by
`lua/plugins/mdpreview.lua`). It opens a live side-by-side pane whose buffer is a
faithful copy of the source markdown (so treesitter nodes, and therefore
`snacks.image` media, stay valid) and renders entirely with extmarks:

- concealed heading markers + per-level rules and a gutter bar;
- `- `→`•`, `[ ]`/`[x]`→`☐`/`☑`, `> `→`▌`, `---`→a full-width rule;
- box-drawn tables and labeled code-block borders;
- inline markup concealed by Neovim's shipped treesitter queries.

`lua/plugins/snacks.lua` now enables `snacks.image`, so ` ```mermaid `, ` ```math `,
and images render as real graphics on Kitty. Verified headlessly on nvim 0.12.2:
pane opens/closes, live edit → re-render, 20–30 extmarks per fixture, no handler
errors. See `docs/mdpreview.md` for usage, config, and limitations.

---

## 13. Sources

- render-markdown.nvim — <https://github.com/MeanderingProgrammer/render-markdown.nvim>
  (docs: `doc/purpose.md`, `doc/limitations.md`, `doc/markdown-ecosystem.md`)
- markview.nvim — <https://github.com/OXY2DEV/markview.nvim>
- markdown-preview.nvim — <https://github.com/iamcco/markdown-preview.nvim>
- peek.nvim — <https://github.com/toppair/peek.nvim>
- snacks.nvim image module — <https://github.com/folke/snacks.nvim/blob/main/docs/image.md>
- image.nvim — <https://github.com/3rd/image.nvim>
- glow.nvim (archived) — <https://github.com/ellisonleao/glow.nvim>
- headlines.nvim — <https://github.com/lukas-reineke/headlines.nvim>
- markdown.nvim — <https://github.com/tadmccorkle/markdown.nvim>
- markdown-oxide — <https://github.com/Feel-ix-343/markdown-oxide>
- latex.nvim — <https://github.com/ryleelyman/latex.nvim>
- LazyVim markdown extra — <https://lazyvim.github.io/extras/lang/markdown>
- Neovim 0.12 news ("Enabled treesitter highlighting for Markdown files") —
  <https://neovim.io/doc/user/news-0.12/>
- Kitty graphics protocol — <https://sw.kovidgoyal.net/kitty/graphics-protocol/>
- tmux passthrough — tmux ≥3.3, `set -gq allow-passthrough on`
- herdr graphics support — <https://herdr.dev/docs/windows-beta/>

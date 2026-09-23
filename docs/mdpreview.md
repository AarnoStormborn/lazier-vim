# mdpreview — an in-terminal markdown preview pane

A from-scratch markdown preview for this config: a **side-by-side pane** or a
**full-screen tab** that renders the markdown live, inside Neovim, without a
browser.

- **Both at once** — source left, preview right (the thing the browser preview
  can't do).
- **Full screen** — one key toggles the render to a whole editor tab.
- **Live** — re-renders as you type (debounced 80 ms).
- **Media** — the preview buffer is a real markdown buffer, so `snacks.image`
  renders ` ```mermaid `, ` ```math `, and inline images as actual graphics.
- **Custom look** — concealed heading markers with per-level rules, bullets,
  checkboxes, quote bars, boxed code blocks, and box-drawn tables.

## Usage

| Action | Command / key |
|---|---|
| Cycle: closed → side-by-side → full screen → closed | `:MdPreview` or `<leader>mp` |
| Toggle full screen directly | `:MdPreviewFull` or `<leader>mP` |
| Close the pane | `:MdPreviewClose` or `q` (in the preview) |
| Existing in-buffer render | `<leader>um` (LazyVim extra) |
| Browser preview | `<leader>cp` (still available) |

Implementation: `lua/mdpreview/` (`init.lua`, `pane.lua`, `render.lua`,
`config.lua`), loaded by `lua/plugins/mdpreview.lua`.

## Test document

[`docs/markdown-sample.md`](markdown-sample.md) exercises every element and edge
case: headings (ATX H1–H6, setext, trailing hashes, empty), inline formatting and
escapes, links (inline/reference/autolink), images, lists (bullets, ordered,
nested, task lists), blockquotes and callouts, code blocks (multiple languages,
tilde fences, indented, no language), tables (alignment, escaped pipes, empty
cells), horizontal rules, ` ```math `, ` ```mermaid `, raw HTML, comments,
frontmatter, footnotes, and long/Unicode/whitespace edge cases.

Open it and run `:MdPreview`.

## How it works

The preview buffer is a **faithful copy of the source markdown** (same lines,
`filetype=markdown`). Rendering is done entirely with extmarks:

- markup is concealed and the replacement is re-inserted **inline** — `# ` → the
  heading text (styled), `- ` → `•`, `[ ]`/`[x]` → `☐`/`☑`, `> ` → `▌`,
  `---` → a full-width rule;
- tables are box-drawn from parsed cells (`│ … │`, `╭─┬─╮` borders);
- code fences get a labeled box (` ╭ lua ─…╮ `);
- headings get per-level rules and spacing;
- frontmatter, HTML comments, and link reference definitions are dimmed;
- inline `**bold**`, `` `code` ``, `[links](…)`, images, etc. are concealed by
  the treesitter queries Neovim already ships in its runtime.

Because the buffer stays valid markdown, `snacks.image` can still find
`mermaid`/`math` fences and image nodes and overlay real graphics. The pane also
disables `render-markdown.nvim` for the preview buffer, so the two renderers
don't fight over it.

> Why not a floating window for full screen? Forced backgrounds look wrong with
> the transparency plugin (the editor would show through). A dedicated tab is a
> true full screen.

## Heading hierarchy

Terminals cannot change font size per line, so `#` vs `##` differ by everything
else that *is* available:

| Level | Rule | Colour source | Weight |
|---|---|---|---|
| H1 | `═` (plus a blank line above) | `@markup.heading.1` → `Title` | bold |
| H2 | `─` | `@markup.heading.2` → `Function` | bold |
| H3 | `┄` | `@markup.heading.3` → `Identifier` | bold |
| H4 | — | `@markup.heading.4` → `Constant` | normal |
| H5 | — | `@markup.heading.5` → `String` | italic |
| H6 | — | `@markup.heading.6` → `Comment` | italic, dim |

## Configuration

Defaults live in `lua/mdpreview/config.lua`. Override them in
`lua/plugins/mdpreview.lua`:

```lua
require("mdpreview").setup({
    pane = { position = "right", width = 0.5, follow_cursor = true },
    headings = {
        conceal = true,
        rules = { [1] = "═", [2] = "─", [3] = "┄" }, -- nil = no rule
        space = { [1] = true }, -- blank line above this level
    },
    table = { border = "rounded" }, -- rounded | single | double
    lists = { bullets = { ["-"] = "•" } },
    checkboxes = { unchecked = "☐", checked = "☑" },
    quote = { icon = "▌" },
    code = { border = true, skip_langs = { math = true, mermaid = true } },
    keymaps = { toggle = "<leader>mp", fullscreen = "<leader>mP", close = "q" },
})
```

The preview window sets `smoothscroll = false` and `scrolloff = 0` so a line is
never left clipped at the top of the pane.

## Media setup (snacks.image)

| Block | Engine | Needs |
|---|---|---|
| ` ```mermaid ` | `mmdc` (`@mermaid-js/mermaid-cli`) | installed |
| ` ```math ` | `tectonic` → PDF → ImageMagick | `tectonic`, `ghostscript`, `imagemagick` — installed |
| `![alt](img.png)` | ImageMagick | installed, plus a terminal with the Kitty graphics protocol |

Math must be a ` ```math ` fenced block, not `$$…$$` — `snacks.image` discovers
media through treesitter nodes, and the markdown grammar has no node for `$`
delimiters.

Terminal support: **kitty** (best) and **kitty via herdr** work; **tmux** needs
`set -gq allow-passthrough on`; **Warp** is inconsistent. Verify with
`:checkhealth snacks`.

Note: `snacks.image` is enabled globally, so media also renders in normal
markdown buffers, not only the preview. Remove `image` from
`lua/plugins/snacks.lua` to turn that off (the preview then shows the raw
fences instead of graphics).

## Current limitations

- Paragraphs are **not reflowed**; the preview mirrors source line breaks (the
  same constraint extmark rendering has in general).
- Table column **alignment** (`:---:`) is ignored; columns are left-aligned.
- Heading **font size** cannot change in a terminal (see the hierarchy table).
- Rendering is **whole-buffer** (debounced 80 ms) rather than visible-range
  only; very large documents may feel heavy.
- Hidden/dimmed frontmatter and comments still occupy their lines — extmark
  conceal cannot remove a buffer line.
- A malformed/unterminated code fence makes everything after it render as code
  (correct Markdown behaviour, but worth knowing when testing).

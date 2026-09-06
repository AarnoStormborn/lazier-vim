# lazier-vim

My personal [LazyVim](https://lazyvim.github.io) Neovim setup, packaged as a portable git repo.

This repo is the **source of truth**. The live config at `~/.config/nvim` is a
symlink into this repo, so edits here take effect immediately (most on reload,
full config on restart). Neovim's own state — installed plugins, LSP servers,
and caches — lives outside the repo under `~/.local/share/nvim` and
`~/.local/state/nvim`, so the repo stays clean and cloneable.

## Layout

```
lazier-vim/
├── .gitignore
├── .editorconfig            # consistent whitespace for this repo's files
├── README.md
├── init.lua                 # bootstraps lazy.nvim + LazyVim
├── lazyvim.json             # LazyVim extras (lang.python/json/markdown/toml/yaml, ui.smear-cursor)
├── .neoconf.json            # neodev/neoconf lua-language-server settings
├── stylua.toml              # 4-space stylua formatting (matches the code here)
├── LICENSE                  # Apache-2.0 (retained from the LazyVim starter)
├── colors/
│   └── cyberwave.vim        # personal Warp "Cyber Wave" colorscheme (local plugin)
├── lua/
│   ├── config/
│   │   ├── autocmds.lua     # (empty placeholder — add autocmds here)
│   │   ├── keymaps.lua      # jj → <Esc>
│   │   ├── lazy.lua         # lazy.nvim setup + plugin import order
│   │   └── options.lua      # pyright LSP, 4-space tabs (shiftwidth etc.)
│   └── plugins/
│       ├── colorscheme.lua  # cyberwave default + catppuccin/kanagawa/rose-pine
│       ├── example.lua      # upstream starter example (kept verbatim, incl. nvim-tree)
│       ├── snacks.lua       # snacks picker: show hidden + gitignored files
│       ├── surround.lua     # nvim-surround
│       ├── telescope.lua    # telescope + fzf-native, show hidden + gitignored
│       └── transparency.lua # cyberwave transparency (self-contained local plugin)
└── install.sh               # wires the symlink; --status / --restore
```

## Install on a new machine

Requirements: `nvim` ≥ 0.11, `git`, `make` + a C compiler (for
`telescope-fzf-native`), and `rg` (ripgrep). Lazy.nvim self-installs on first
launch and fetches every plugin and LSP server for you.

```bash
git clone git@github.com:AarnoStormborn/lazier-vim ~/lazier-vim
cd ~/lazier-vim
./install.sh                # backs up any existing ~/.config/nvim, then symlinks it to this repo
nvim                        # lazy.nvim bootstraps itself; installs LazyVim + your plugins
```

Then commit `lazy-lock.json` if `:Lazy` changed it, and optionally run
`:Lazy restore` to pin the exact plugin versions listed in the lockfile.

## Relationship to the LazyVim starter

This repo is **not** a fork of `LazyVim/starter` and has no live upstream git
history. It is a clean snapshot of the starter plus my customizations:

- The *real* LazyVim logic is a plugin that lazy.nvim installs into
  `~/.local/share/nvim/lazy/LazyVim` and updates with `:Lazy update` — it is
  **not** part of this repo's history.
- The starter's config scaffolding (`lua/config/*.lua`, `lua/plugins/example.lua`,
  `init.lua`, `stylua.toml`) was snapshotted once. Since LazyVim's own code is
  a plugin, new starter improvements reach you through `:Lazy update` too.
- If a future starter scaffolding change is genuinely needed (rare — e.g. a new
  bootstrap requirement in `lua/config/lazy.lua`), port it manually and commit
  with a `sync: port from LazyVim/starter@<sha>` message so history stays
  reviewable.

## Daily use

- Edit files here; the live config follows via the symlink.
- `./install.sh --status` — verify the link is healthy on any machine.
- `./install.sh --restore` — undo the symlink and restore the pre-install backup.
- Commit and push from this repo to back everything up.

## Excluded by design

- `lazy-lock.json`, `.git`, `data`, `doc/tags`, `tt.*`, `.tests`, logs —
  covered by `.gitignore`.
- Plugin installs (`~/.local/share/nvim/lazy`), LSP servers
  (`~/.local/share/nvim/mason`), and all editor state (`~/.local/state/nvim`,
  `~/.local/share/nvim/snacks`, `telescope_history`) — never packaged.
- Secrets, tokens, or machine-local settings — never packaged.

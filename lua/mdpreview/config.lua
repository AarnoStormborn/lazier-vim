-- mdpreview: a from-scratch, block-level markdown renderer for a side-by-side
-- (or full-screen) Neovim pane.
--
-- Design: the preview buffer is a faithful copy of the source markdown, so
-- treesitter nodes (and therefore snacks.image media rendering) stay intact.
-- Rendering is done purely with extmarks: markup is concealed and replaced with
-- drawn text (heading rules, bullets, checkboxes, quote bars, box tables,
-- boxed code blocks). Inline markup (bold/italic/code/links) is concealed by the
-- treesitter queries Neovim ships in its runtime.
local M = {}

M.defaults = {
    pane = {
        position = "right", -- right | left | above | below
        width = 0.5, -- fraction of columns, vertical splits
        height = 0.4, -- fraction of lines, horizontal splits
        follow_cursor = true, -- keep preview cursor on the same source line
        win_options = {
            conceallevel = 3,
            concealcursor = "nc",
            wrap = true,
            linebreak = true,
            number = false,
            relativenumber = false,
            signcolumn = "no",
            foldcolumn = "0",
            spell = false,
            cursorline = false,
            list = false,
            winbar = "",
            -- keep whole lines visible: smoothscroll can leave a clipped
            -- half-line at the top of the window
            smoothscroll = false,
            scrolloff = 0,
            sidescrolloff = 0,
        },
    },
    headings = {
        conceal = true, -- hide the leading #
        -- per-level underline rule; nil = no rule. Wider/heavier = higher level.
        rules = { [1] = "═", [2] = "─", [3] = "┄" },
        -- blank line above a level, for extra visual weight
        space = { [1] = true },
    },
    lists = {
        bullets = { ["-"] = "•", ["*"] = "•", ["+"] = "•" },
    },
    checkboxes = {
        unchecked = "☐",
        checked = "☑",
    },
    quote = {
        icon = "▌",
    },
    rules = {
        char = "─",
    },
    table = {
        enabled = true,
        border = "rounded", -- rounded | single | double
    },
    code = {
        border = true,
        -- Languages owned by snacks.image; don't draw a code box around them.
        skip_langs = { math = true, mermaid = true },
    },
    keymaps = {
        toggle = "<leader>mp", -- cycle: closed -> side-by-side -> full screen
        fullscreen = "<leader>mP", -- toggle full screen directly
        close = "q", -- inside the preview
    },
}

M.options = vim.deepcopy(M.defaults)

return M

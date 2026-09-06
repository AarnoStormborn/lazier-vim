-- Colorscheme setup: Warp "Cyber Wave" inspired theme (local, no deps)
-- Palette source: https://github.com/warpdotdev/themes/blob/main/warp_bundled/cyber_wave.yaml
return {
    -- Local colorscheme plugin (colors/cyberwave.vim)
    {
        dir = vim.fn.stdpath("config") .. "/colors",
        name = "cyberwave",
        priority = 1000, -- load first so it wins over other colorschemes
        lazy = false,
    },
    { "catppuccin/nvim", name = "catppuccin", lazy = true },
    {
        "rebelot/kanagawa.nvim",
        lazy = true,
        opts = {
            theme = "wave",
        },
    },
    {
        "rose-pine/neovim",
        name = "rose-pine",
        lazy = false,
        opts = {
            variant = "moon",
            dark_variant = "moon",
        },
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "cyberwave",
        },
    },
}

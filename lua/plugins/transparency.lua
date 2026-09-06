-- cyberwave transparency: make the cyberwave colorscheme transparent
-- so the terminal background (Warp at 80% opacity) shows through,
-- matching Warp's own 20% transparency.
--
-- Approach:
--   * Clear the guibg of the main background surfaces (Normal, floats,
--     statusline, tabs, popups) so the terminal blends through.
--   * Use winblend on floating windows for a subtle translucent depth.
--   * Re-apply on ColorScheme so re-loading the scheme keeps transparency.
--
-- This is a self-contained plugin (dir = this folder), no external deps.
return {
    dir = vim.fn.stdpath("config") .. "/lua/plugins",
    name = "cyberwave-transparency",
    lazy = false,
    priority = 900, -- after the colorscheme (1000) but before other UI plugins
    config = function()
        -- Main surfaces to make transparent (keep their fg).
        -- Selection/search/diff keep their bg for readability.
        local transparent = {
            "Normal", "NormalNC", "SignColumn", "FoldColumn",
            "VertSplit", "WinSeparator", "TabLine", "TabLineFill",
            "StatusLine", "StatusLineNC", "NormalFloat", "Pmenu",
        }

        local function apply_transparency()
            for _, group in ipairs(transparent) do
                local ok, hl = pcall(vim.api.nvim_get_hl_by_name, group, true)
                if ok then
                    local fg = hl.foreground
                    local hi = { fg = fg and string.format("#%06x", fg) }
                    vim.api.nvim_set_hl(0, group, hi)
                end
            end
            -- subtle translucent depth for floats/popups
            vim.opt.winblend = 10
            vim.opt.pumblend = 10
        end

        apply_transparency()

        -- LazyVim / colorscheme plugins may re-set backgrounds on ColorScheme
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("cyberwave_transparency", { clear = true }),
            callback = apply_transparency,
        })
    end,
}

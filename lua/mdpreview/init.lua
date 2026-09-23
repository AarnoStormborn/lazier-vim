-- mdpreview: a from-scratch markdown preview pane for Neovim.
--
--   require("mdpreview").setup({ ... })   -- configure once
--   :MdPreview / <leader>mp               -- cycle: closed -> split -> full
--   :MdPreviewFull / <leader>mP           -- toggle full screen
--
-- The preview buffer is a faithful copy of the source markdown, rendered purely
-- with extmarks (see render.lua), so treesitter nodes stay intact and
-- snacks.image can render ```mermaid / ```math blocks and inline images.
local config = require("mdpreview.config")
local pane = require("mdpreview.pane")

local M = {}

---Define `name` from the first base highlight that has attributes, plus extras.
---@param name string
---@param bases string[]
---@param extra table
local function derive(name, bases, extra)
    for _, base in ipairs(bases) do
        local hl = vim.api.nvim_get_hl(0, { name = base })
        if hl and next(hl) then
            hl.link = nil
            for k, v in pairs(extra or {}) do
                hl[k] = v
            end
            vim.api.nvim_set_hl(0, name, hl)
            return
        end
    end
    vim.api.nvim_set_hl(0, name, extra or {})
end

local function define_highlights()
    local hl = vim.api.nvim_set_hl

    -- Heading hierarchy. Terminals can't change font size, so level is conveyed
    -- by colour, weight, rule character, and spacing (see config.headings).
    derive("MdPreviewH1", { "@markup.heading.1", "Title" }, { bold = true })
    derive("MdPreviewH2", { "@markup.heading.2", "Function" }, { bold = true })
    derive("MdPreviewH3", { "@markup.heading.3", "Identifier" }, { bold = true })
    derive("MdPreviewH4", { "@markup.heading.4", "Constant" }, {})
    derive("MdPreviewH5", { "@markup.heading.5", "String" }, { italic = true })
    derive("MdPreviewH6", { "@markup.heading.6", "Comment" }, { italic = true, dim = true })

    hl(0, "MdPreviewRule1", { link = "MdPreviewH1" })
    hl(0, "MdPreviewRule2", { link = "MdPreviewH2" })
    hl(0, "MdPreviewRule3", { link = "MdPreviewH3" })
    hl(0, "MdPreviewRule", { link = "WinSeparator" })
    hl(0, "MdPreviewBullet", { link = "Special" })
    hl(0, "MdPreviewListNumber", { link = "Special" })
    hl(0, "MdPreviewQuote", { link = "Comment" })
    hl(0, "MdPreviewCheckboxUnchecked", { link = "DiagnosticInfo" })
    hl(0, "MdPreviewCheckboxChecked", { link = "DiagnosticOk" })
    hl(0, "MdPreviewTableBorder", { link = "Comment" })
    hl(0, "MdPreviewTableHeader", { link = "MdPreviewH3" })
    hl(0, "MdPreviewTableRow", { link = "Normal" })
    hl(0, "MdPreviewCodeBorder", { link = "Comment" })
    hl(0, "MdPreviewMeta", { link = "Comment" })
end

---@param opts? table
function M.setup(opts)
    config.options = vim.tbl_deep_extend("force", config.defaults, opts or {})
    define_highlights()

    vim.api.nvim_create_user_command("MdPreview", function()
        pane.toggle(config.options)
    end, { desc = "Toggle the markdown preview pane (split -> full -> closed)" })

    vim.api.nvim_create_user_command("MdPreviewFull", function()
        pane.toggle_full(config.options)
    end, { desc = "Toggle the markdown preview full screen" })

    vim.api.nvim_create_user_command("MdPreviewClose", function()
        pane.close()
    end, { desc = "Close the markdown preview pane" })

    local keys = config.options.keymaps
    if keys.toggle and keys.toggle ~= "" then
        vim.keymap.set("n", keys.toggle, function()
            pane.toggle(config.options)
        end, { desc = "Markdown preview (split/full/close)" })
    end
    if keys.fullscreen and keys.fullscreen ~= "" then
        vim.keymap.set("n", keys.fullscreen, function()
            pane.toggle_full(config.options)
        end, { desc = "Markdown preview full screen" })
    end
end

---@param buf? integer
function M.open(buf)
    return pane.open(buf, config.options)
end

function M.close()
    pane.close()
end

function M.toggle()
    pane.toggle(config.options)
end

function M.toggle_full()
    pane.toggle_full(config.options)
end

---@param buf? integer
---@return boolean
function M.is_open(buf)
    return pane.is_open(buf or vim.api.nvim_get_current_buf())
end

M.config = config

return M

-- mdpreview: a from-scratch markdown preview pane.
--
-- Side-by-side live preview rendered with extmarks in a normal markdown buffer,
-- so treesitter stays valid and snacks.image can render ```mermaid / ```math
-- blocks and inline images. Implementation lives in lua/mdpreview/.
--
--   :MdPreview        toggle the pane
--   <leader>mp        same
--
-- This is a local plugin (dir = lua/mdpreview), no external deps.
return {
    dir = vim.fn.stdpath("config") .. "/lua/mdpreview",
    name = "mdpreview",
    lazy = false,
    priority = 800,
    config = function()
        require("mdpreview").setup({
            -- Defaults live in lua/mdpreview/config.lua; override here, e.g.
            -- pane = { position = "right", width = 0.5 },
            -- table = { border = "rounded" },
        })
    end,
}

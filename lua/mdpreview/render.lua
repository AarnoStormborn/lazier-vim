-- mdpreview.render: block-level extmark renderer.
--
-- Everything here draws into the preview buffer without changing its text, so
-- the buffer stays valid markdown for treesitter and snacks.image.
--
-- Conceal semantics (verified on nvim 0.12): an extmark `conceal` hides the
-- range and removes its width, and a non-empty conceal char is NOT drawn.
-- Replacement glyphs therefore use `virt_text_pos = "inline"`, which inserts
-- text into the flow instead of overlaying (and covering) the shifted text.
local M = {}

local NS = vim.api.nvim_create_namespace("mdpreview")

---@param buf integer
---@param row integer
---@return string
local function line(buf, row)
    return vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
end

---@param buf integer
---@param node TSNode
---@return string
local function text(buf, node)
    return vim.treesitter.get_node_text(node, buf)
end

---Visible width of a raw markdown cell/string (strip inline markup).
---@param s string
---@return string
local function strip_inline(s)
    s = s:gsub("%s+$", "")
    s = s:gsub("%[%[([^%]]*)%]%]", "%1")
    s = s:gsub("%[([^%]]*)%]%([^%)]*%)", "%1")
    s = s:gsub("!%[([^%]]*)%]%([^%)]*%)", "%1")
    s = s:gsub("%*%*(.-)%*%*", "%1")
    s = s:gsub("__(.-)__", "%1")
    s = s:gsub("~~(.-)~~", "%1")
    s = s:gsub("`([^`]*)`", "%1")
    s = s:gsub("%*(.-)%*", "%1")
    s = s:gsub("_(.-)_", "%1")
    s = s:gsub("&nbsp;", " "):gsub("&amp;", "&"):gsub("&lt;", "<"):gsub("&gt;", ">")
    return s
end

---@param win integer
---@return integer
local function win_width(win)
    return math.max(20, vim.api.nvim_win_get_width(win) - 2)
end

---Hide a range and optionally insert replacement cells into the text flow.
---@param buf integer
---@param row integer
---@param col integer
---@param to_col integer
---@param virt? [string, string][]
local function replace(buf, row, col, to_col, virt)
    local mark = { end_col = to_col, conceal = "" }
    if virt then
        mark.virt_text = virt
        mark.virt_text_pos = "inline"
    end
    pcall(vim.api.nvim_buf_set_extmark, buf, NS, row, col, mark)
end

---Replace an entire line's visible text with drawn content.
---@param buf integer
---@param row integer
---@param drawn string
---@param hl string
local function replace_line(buf, row, drawn, hl)
    local l = line(buf, row)
    pcall(vim.api.nvim_buf_set_extmark, buf, NS, row, 0, {
        end_col = #l,
        conceal = "",
        virt_text = { { drawn, hl } },
        virt_text_win_col = 0,
    })
end

---Hide every line of a node.
---@param buf integer
---@param node TSNode
local function hide_node(buf, node)
    local sr, _, er, ec = node:range()
    for row = sr, er do
        if row < er or ec > 0 then
            local l = line(buf, row)
            if #l > 0 then
                replace(buf, row, 0, #l, nil)
            end
        end
    end
end

---Dim every line of a node (no blank lines left behind).
---@param buf integer
---@param node TSNode
---@param hl string
local function dim_node(buf, node, hl)
    local sr, _, er, ec = node:range()
    for row = sr, er do
        if row < er or ec > 0 then
            local l = line(buf, row)
            if #l > 0 then
                pcall(vim.api.nvim_buf_set_extmark, buf, NS, row, 0, {
                    end_col = #l,
                    hl_group = hl,
                    priority = 110,
                })
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Headings
-- ---------------------------------------------------------------------------

local HEADING_MARKERS = {
    atx_h1_marker = 1,
    atx_h2_marker = 2,
    atx_h3_marker = 3,
    atx_h4_marker = 4,
    atx_h5_marker = 5,
    atx_h6_marker = 6,
}

---@param buf integer
---@param row integer
---@param level integer
---@param opts table
---@param win integer
local function style_heading(buf, row, level, opts, win)
    local l = line(buf, row)
    vim.api.nvim_buf_set_extmark(buf, NS, row, 0, {
        end_col = #l,
        hl_group = "MdPreviewH" .. level,
        priority = 120,
    })
    if opts.headings.space[level] then
        vim.api.nvim_buf_set_extmark(buf, NS, row, 0, {
            virt_lines = { { { "", "Normal" } } },
            virt_lines_above = true,
        })
    end
    local rule = opts.headings.rules[level]
    if rule then
        local width = win_width(win)
        vim.api.nvim_buf_set_extmark(buf, NS, row, 0, {
            virt_lines = { { { string.rep(rule, width), "MdPreviewRule" .. level } } },
            virt_lines_above = false,
        })
    end
end

---@param buf integer
---@param node TSNode
---@param opts table
---@param win integer
local function render_heading(buf, node, opts, win)
    local row = node:range()
    local marker = node:child(0)
    if not marker then
        return
    end
    local level = HEADING_MARKERS[marker:type()]
    if not level then
        return
    end

    if opts.headings.conceal then
        local _, _, _, m_end = marker:range()
        local l = line(buf, row)
        local to_col = m_end
        while l:sub(to_col + 1, to_col + 1) == " " do
            to_col = to_col + 1
        end
        replace(buf, row, 0, to_col, nil)
        -- optional closing sequence: `## Heading ##`
        local trail = l:find("#+%s*$")
        if trail and trail - 1 >= to_col and trail > 1 then
            replace(buf, row, trail - 1, #l, nil)
        end
    end

    style_heading(buf, row, level, opts, win)
end

---@param buf integer
---@param node TSNode
---@param opts table
---@param win integer
local function render_setext(buf, node, opts, win)
    local srow = node:range()
    local level = 2
    local underline_row
    for child in node:iter_children() do
        local t = child:type()
        if t == "setext_h1_underline" then
            level, underline_row = 1, child:range()
        elseif t == "setext_h2_underline" then
            level, underline_row = 2, child:range()
        end
    end
    if underline_row then
        replace(buf, underline_row, 0, #line(buf, underline_row), nil)
    end
    style_heading(buf, srow, level, opts, win)
end

-- ---------------------------------------------------------------------------
-- Lists, task markers, quotes, rules
-- ---------------------------------------------------------------------------

---@param buf integer
---@param node TSNode
---@param opts table
local function render_list_marker(buf, node, opts)
    local t = node:type()
    local srow, scol, _, ecol = node:range()
    if t == "list_marker_minus" or t == "list_marker_star" or t == "list_marker_plus" then
        local ch = text(buf, node):match("^%S")
        local bullet = opts.lists.bullets[ch] or "•"
        replace(buf, srow, scol, ecol, { { bullet .. " ", "MdPreviewBullet" } })
    else
        vim.api.nvim_buf_set_extmark(buf, NS, srow, scol, {
            end_col = ecol,
            hl_group = "MdPreviewListNumber",
            priority = 120,
        })
    end
end

---@param buf integer
---@param node TSNode
---@param opts table
local function render_task(buf, node, opts)
    local checked = node:type() == "task_list_marker_checked"
    local srow, scol, _, ecol = node:range()
    local icon = checked and opts.checkboxes.checked or opts.checkboxes.unchecked
    local hl = checked and "MdPreviewCheckboxChecked" or "MdPreviewCheckboxUnchecked"
    replace(buf, srow, scol, ecol, { { icon .. " ", hl } })
end

---@param buf integer
---@param node TSNode
---@param opts table
local function render_quote_marker(buf, node, opts)
    if not text(buf, node):match("^%s*>") then
        return
    end
    local srow, scol, _, ecol = node:range()
    replace(buf, srow, scol, ecol, { { opts.quote.icon .. " ", "MdPreviewQuote" } })
end

---@param buf integer
---@param node TSNode
---@param opts table
local function render_rule(buf, node, opts, win)
    local srow = node:range()
    replace_line(buf, srow, string.rep(opts.rules.char, win_width(win)), "MdPreviewRule")
end

---Frontmatter, HTML comments and link reference definitions are noise in a
---preview: dim them instead of leaving blank lines behind.
---@param buf integer
---@param node TSNode
local function render_metadata(buf, node)
    dim_node(buf, node, "MdPreviewMeta")
end

---@param buf integer
---@param node TSNode
local function render_reference(buf, node)
    dim_node(buf, node, "MdPreviewMeta")
end

---@param buf integer
---@param node TSNode
local function render_comment(buf, node)
    if text(buf, node):match("^%s*<!%-%-") then
        dim_node(buf, node, "MdPreviewMeta")
    end
end

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

local BORDERS = {
    rounded = {
        tl = "╭",
        tm = "┬",
        tr = "╮",
        ml = "├",
        mm = "┼",
        mr = "┤",
        bl = "╰",
        bm = "┴",
        br = "╯",
        h = "─",
        v = "│",
    },
    single = {
        tl = "┌",
        tm = "┬",
        tr = "┐",
        ml = "├",
        mm = "┼",
        mr = "┤",
        bl = "└",
        bm = "┴",
        br = "┘",
        h = "─",
        v = "│",
    },
    double = {
        tl = "╔",
        tm = "╦",
        tr = "╗",
        ml = "╠",
        mm = "╬",
        mr = "╣",
        bl = "╚",
        bm = "╩",
        br = "╝",
        h = "═",
        v = "║",
    },
}

---@param buf integer
---@param node TSNode
---@param opts table
local function render_table(buf, node, opts)
    if not opts.table.enabled then
        return
    end
    local b = BORDERS[opts.table.border] or BORDERS.rounded

    ---@type { node: TSNode, cells?: string[], delimiter?: boolean }[]
    local rows = {}
    for child in node:iter_children() do
        local ct = child:type()
        if ct == "pipe_table_header" or ct == "pipe_table_row" then
            local cells = {}
            for cell in child:iter_children() do
                if cell:type() == "pipe_table_cell" then
                    cells[#cells + 1] = strip_inline(text(buf, cell))
                end
            end
            rows[#rows + 1] = { node = child, cells = cells }
        elseif ct == "pipe_table_delimiter_row" then
            rows[#rows + 1] = { node = child, delimiter = true }
        end
    end

    local ncol = 0
    for _, r in ipairs(rows) do
        if r.cells then
            ncol = math.max(ncol, #r.cells)
        end
    end
    if ncol == 0 then
        return
    end

    local widths = {}
    for i = 1, ncol do
        widths[i] = 1
    end
    for _, r in ipairs(rows) do
        if r.cells then
            for i = 1, ncol do
                widths[i] = math.max(widths[i], vim.fn.strdisplaywidth(r.cells[i] or ""))
            end
        end
    end

    local function border(l, m, rr)
        local parts = {}
        for i = 1, ncol do
            parts[i] = string.rep(b.h, widths[i] + 2)
        end
        return l .. table.concat(parts, m) .. rr
    end

    local function row(cells)
        local parts = {}
        for i = 1, ncol do
            local c = cells[i] or ""
            local pad = widths[i] - vim.fn.strdisplaywidth(c)
            parts[i] = " " .. c .. string.rep(" ", pad) .. " "
        end
        return b.v .. table.concat(parts, b.v) .. b.v
    end

    for idx, r in ipairs(rows) do
        local srow = r.node:range()
        local is_header = r.node:type() == "pipe_table_header"
        if r.delimiter then
            replace_line(buf, srow, border(b.ml, b.mm, b.mr), "MdPreviewTableBorder")
        elseif is_header then
            replace_line(buf, srow, row(r.cells), "MdPreviewTableHeader")
            vim.api.nvim_buf_set_extmark(buf, NS, srow, 0, {
                virt_lines = { { { border(b.tl, b.tm, b.tr), "MdPreviewTableBorder" } } },
                virt_lines_above = true,
            })
        else
            replace_line(buf, srow, row(r.cells), "MdPreviewTableRow")
        end
        if idx == #rows then
            vim.api.nvim_buf_set_extmark(buf, NS, srow, 0, {
                virt_lines = { { { border(b.bl, b.bm, b.br), "MdPreviewTableBorder" } } },
            })
        end
    end
end

-- ---------------------------------------------------------------------------
-- Fenced code blocks
-- ---------------------------------------------------------------------------

---@param buf integer
---@param node TSNode
---@param opts table
---@param win integer
local function render_fence(buf, node, opts, win)
    if not opts.code.border then
        return
    end
    local srow = node:range()
    local lang = ""
    local last = srow
    for child in node:iter_children() do
        local ct = child:type()
        if ct == "info_string" then
            lang = text(buf, child)
        elseif ct == "fenced_code_block_delimiter" then
            last = child:range()
        end
    end
    if opts.code.skip_langs and opts.code.skip_langs[lang] then
        return
    end
    local width = win_width(win)
    local label = lang ~= "" and (" " .. lang .. " ") or ""
    local fill = math.max(0, width - #label - 2)
    local top = "╭" .. label .. string.rep("─", fill) .. "╮"
    local bottom = "╰" .. string.rep("─", width - 2) .. "╯"
    -- The treesitter query conceals the fence lines; draw the box on top.
    replace_line(buf, srow, top, "MdPreviewCodeBorder")
    if last ~= srow then
        replace_line(buf, last, bottom, "MdPreviewCodeBorder")
    end
end

-- ---------------------------------------------------------------------------
-- Driver
-- ---------------------------------------------------------------------------

local HANDLERS = {
    atx_heading = render_heading,
    setext_heading = render_setext,
    list_marker_minus = render_list_marker,
    list_marker_star = render_list_marker,
    list_marker_plus = render_list_marker,
    list_marker_dot = render_list_marker,
    list_marker_parenthesis = render_list_marker,
    task_list_marker_unchecked = render_task,
    task_list_marker_checked = render_task,
    block_quote_marker = render_quote_marker,
    block_continuation = render_quote_marker,
    thematic_break = render_rule,
    minus_metadata = render_metadata,
    plus_metadata = render_metadata,
    link_reference_definition = render_reference,
    html_block = render_comment,
    pipe_table = render_table,
    fenced_code_block = render_fence,
}

---Render the whole buffer.
---@param buf integer
---@param win integer
---@param opts table
function M.render(buf, win, opts)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end
    vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)

    for k, v in pairs(opts.pane.win_options) do
        pcall(vim.api.nvim_set_option_value, k, v, { win = win })
    end

    local ok, parser = pcall(vim.treesitter.get_parser, buf, "markdown")
    if not ok or not parser then
        return
    end
    local ok2, tree = pcall(function()
        return parser:parse()[1]
    end)
    if not ok2 or not tree then
        return
    end

    local function walk(node)
        local handler = HANDLERS[node:type()]
        if handler then
            local ok3, err = pcall(handler, buf, node, opts, win)
            if not ok3 and opts.debug then
                vim.notify("mdpreview: " .. tostring(err), vim.log.levels.ERROR)
            end
        end
        for child in node:iter_children() do
            walk(child)
        end
    end
    local okw, errw = pcall(walk, tree:root())
    if not okw and opts.debug then
        vim.notify("mdpreview walk: " .. tostring(errw), vim.log.levels.ERROR)
    end
end

return M

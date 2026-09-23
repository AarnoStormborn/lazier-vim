-- mdpreview.pane: lifecycle for the preview window (side-by-side or full screen).
local render = require("mdpreview.render")

local M = {}

local augroup = vim.api.nvim_create_augroup("MdPreview", { clear = true })
local refresh_seq = 0
local switching = false

---@class MdPreviewPane
---@field src integer source buffer
---@field buf integer preview buffer
---@field win integer current preview window
---@field full boolean full-screen tab?
---@field full_tab integer? the full-screen tabpage
---@field opts table

---@type MdPreviewPane?
local pane = nil

---@return MdPreviewPane?
function M.current()
    return pane
end

---@param src integer
---@return boolean
function M.is_open(src)
    return pane ~= nil and pane.src == src
end

---@param src integer
---@return integer
local function source_window(src)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == src then
            return win
        end
    end
    return 0
end

---@param p MdPreviewPane
local function apply_cursor(p)
    if not vim.api.nvim_win_is_valid(p.win) then
        return
    end
    local sw = source_window(p.src)
    if sw == 0 then
        return
    end
    local row = vim.api.nvim_win_get_cursor(sw)[1]
    pcall(vim.api.nvim_win_set_cursor, p.win, { row, 0 })
    vim.api.nvim_win_call(p.win, function()
        pcall(vim.cmd, "normal! zz")
    end)
end

---@param p MdPreviewPane
local function refresh(p)
    if not (vim.api.nvim_buf_is_valid(p.src) and vim.api.nvim_buf_is_valid(p.buf)) then
        M.close()
        return
    end
    local lines = vim.api.nvim_buf_get_lines(p.src, 0, -1, false)
    vim.api.nvim_set_option_value("modifiable", true, { buf = p.buf })
    vim.api.nvim_buf_set_lines(p.buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = p.buf })
    render.render(p.buf, p.win, p.opts)
end

---@param p MdPreviewPane
local function schedule_refresh(p)
    refresh_seq = refresh_seq + 1
    local seq = refresh_seq
    vim.defer_fn(function()
        if seq == refresh_seq and pane == p then
            refresh(p)
        end
    end, 80)
end

---@param win? integer
local function close_window(win)
    if win and vim.api.nvim_win_is_valid(win) then
        pcall(vim.api.nvim_win_close, win, true)
    end
end

---@param p MdPreviewPane
local function open_split(p)
    local opts = p.opts
    local win = vim.api.nvim_open_win(p.buf, false, { split = opts.pane.position })
    if opts.pane.position == "above" or opts.pane.position == "below" then
        vim.api.nvim_win_set_height(win, math.max(5, math.floor(vim.o.lines * opts.pane.height)))
    else
        vim.api.nvim_win_set_width(win, math.max(20, math.floor(vim.o.columns * opts.pane.width)))
    end
    p.win, p.full = win, false
end

---@param p MdPreviewPane
local function open_full(p)
    vim.cmd("tabnew")
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, p.buf)
    p.win, p.full = win, true
    p.full_tab = vim.api.nvim_get_current_tabpage()
end

---Switch between side-by-side and full screen without losing the buffer.
---@param p MdPreviewPane
---@param full boolean
local function set_full(p, full)
    if p.full == full then
        return
    end
    switching = true
    if full then
        close_window(p.win) -- close the split; the buffer survives (bufhidden=hide)
        open_full(p) -- new tab, preview only
    else
        local sw = source_window(p.src)
        if sw ~= 0 then
            pcall(vim.api.nvim_set_current_win, sw)
        end
        if p.full_tab and vim.api.nvim_tabpage_is_valid(p.full_tab) then
            pcall(vim.cmd, "tabclose " .. vim.api.nvim_tabpage_get_number(p.full_tab))
        end
        open_split(p)
        sw = source_window(p.src)
        if sw ~= 0 then
            pcall(vim.api.nvim_set_current_win, sw)
        end
    end
    switching = false

    render.render(p.buf, p.win, p.opts)
    if p.opts.pane.follow_cursor then
        apply_cursor(p)
    end
end

function M.close()
    if not pane then
        return
    end
    refresh_seq = refresh_seq + 1 -- cancel pending refresh
    local p = pane
    pane = nil
    switching = true
    vim.api.nvim_clear_autocmds({ group = augroup })
    close_window(p.win)
    if vim.api.nvim_buf_is_valid(p.buf) then
        pcall(vim.api.nvim_buf_delete, p.buf, { force = true })
    end
    switching = false
end

---@param src? integer
---@param opts table
---@return MdPreviewPane?
function M.open(src, opts)
    src = src or vim.api.nvim_get_current_buf()
    if M.is_open(src) then
        M.close()
        return nil
    end
    M.close()

    local name = vim.api.nvim_buf_get_name(src)
    local buf = vim.api.nvim_create_buf(false, true)
    if name ~= "" then
        pcall(vim.api.nvim_buf_set_name, buf, name .. " [mdpreview]")
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.api.nvim_buf_get_lines(src, 0, -1, false))
    for k, v in pairs({ bufhidden = "hide", buftype = "nofile", swapfile = false, undofile = false }) do
        vim.api.nvim_set_option_value(k, v, { buf = buf })
    end
    vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })

    pane = { src = src, buf = buf, win = 0, full = false, opts = opts }
    local p = pane

    open_split(p)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
    vim.api.nvim_set_option_value("readonly", true, { buf = buf })

    -- render-markdown.nvim also attaches to filetype=markdown buffers; keep it
    -- out of the preview so the two renderers don't fight over the buffer.
    pcall(function()
        require("render-markdown.core.manager").set_buf(buf, false)
    end)

    local close_key = opts.keymaps and opts.keymaps.close
    if close_key and close_key ~= "" then
        vim.keymap.set("n", close_key, function()
            M.close()
        end, { buffer = buf, nowait = true, desc = "Close preview" })
    end

    pcall(vim.treesitter.start, buf, "markdown")

    local sw = source_window(src)
    if sw ~= 0 then
        pcall(vim.api.nvim_set_current_win, sw)
    end

    render.render(buf, p.win, opts)
    if opts.pane.follow_cursor then
        apply_cursor(p)
    end

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        group = augroup,
        buffer = src,
        callback = function()
            schedule_refresh(p)
        end,
    })
    if opts.pane.follow_cursor then
        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            group = augroup,
            buffer = src,
            callback = function()
                apply_cursor(p)
            end,
        })
    end
    vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
        group = augroup,
        buffer = src,
        callback = function()
            M.close()
        end,
    })
    vim.api.nvim_create_autocmd("WinClosed", {
        group = augroup,
        callback = function(args)
            if switching or not pane then
                return
            end
            if tostring(pane.win) == args.match then
                M.close()
            end
        end,
    })
    vim.api.nvim_create_autocmd("VimResized", {
        group = augroup,
        callback = function()
            if not pane or not vim.api.nvim_win_is_valid(pane.win) then
                return
            end
            render.render(pane.buf, pane.win, pane.opts)
        end,
    })

    return pane
end

---Cycle: closed -> side-by-side -> full screen -> closed.
---@param opts table
function M.toggle(opts)
    if not pane then
        M.open(vim.api.nvim_get_current_buf(), opts)
    elseif not pane.full then
        set_full(pane, true)
    else
        M.close()
    end
end

---Toggle full screen, opening the pane first if needed.
---@param opts table
function M.toggle_full(opts)
    if not pane then
        M.open(vim.api.nvim_get_current_buf(), opts)
        if pane then
            set_full(pane, true)
        end
    else
        set_full(pane, not pane.full)
    end
end

return M

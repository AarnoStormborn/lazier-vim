" cyberwave.vim — Neovim colorscheme based on Warp Terminal's "Cyber Wave" theme
" Palette source: https://github.com/warpdotdev/themes/blob/main/warp_bundled/cyber_wave.yaml
" Requires: Neovim 0.10+ (vim.api / vim.g / treesitter groups)
" Usage: :colorscheme cyberwave

highlight clear
if exists("syntax_on")
  syntax reset
endif

let g:colors_name = "cyberwave"
set background=dark

" ---------------------------------------------------------------------------
" Warp "Cyber Wave" palette
" ---------------------------------------------------------------------------
let s:bg        = "#002633" " terminal background top
let s:bg_deep   = "#00131b" " darker panels (sidebars, menus)
let s:bg_black  = "#000000" " terminal background bottom
let s:bg_panel  = "#0a2f3c" " elevated panels (popups, floats)
let s:bg_sel    = "#103d4d" " selection / current line
let s:bg_hl     = "#1a5c6e" " highlight / search
let s:fg        = "#f1f1f1" " soft white foreground
let s:fg_bright = "#ffffff" " pure white
let s:white_bright = "#ffffff" " cursor / pure white
let s:fg_dim    = "#a5a5a5" " dimmed text
let s:comment   = "#8e8e8e" " comments (warp bright black)
let s:gray      = "#616161" " warp black
let s:teal      = "#16e6c9" " primary accent teal
let s:teal_dark = "#007972" " accent left (warp)
let s:cyan      = "#d0d1fe" " soft periwinkle
let s:blue      = "#26add0" " string / constant blue
let s:blue_soft = "#a5d5fe" " warp blue
let s:green     = "#b4fa72" " warp green
let s:yellow    = "#fefdc2" " warp yellow
let s:pink      = "#ff8ffd" " warp magenta
let s:purple    = "#7b008f" " accent right (warp)
let s:lavender  = "#cdcefb" " keywords / types
let s:red       = "#ff8272" " warp red
let s:white     = "#f1f1f1"

" ---------------------------------------------------------------------------
" Highlight helper: takes a dict of {guifg, guibg, gui, guisp}
" ---------------------------------------------------------------------------
function! s:hi(group, ...) abort
  let l:opts = get(a:, 1, {})
  let l:cmd = ['highlight', a:group]
  if has_key(l:opts, 'guifg')
    call add(l:cmd, 'guifg=' . l:opts.guifg)
  endif
  if has_key(l:opts, 'guibg')
    call add(l:cmd, 'guibg=' . l:opts.guibg)
  endif
  if has_key(l:opts, 'gui')
    call add(l:cmd, 'gui=' . l:opts.gui)
  endif
  if has_key(l:opts, 'guisp')
    call add(l:cmd, 'guisp=' . l:opts.guisp)
  endif
  execute join(l:cmd, ' ')
endfunction

" ---------------------------------------------------------------------------
" Editor base
" ---------------------------------------------------------------------------
call s:hi('Normal',      {'guifg': s:fg,       'guibg': s:bg})
call s:hi('NormalFloat', {'guifg': s:fg,       'guibg': s:bg_panel})
call s:hi('NormalNC',    {'guifg': s:fg_dim,   'guibg': s:bg})
call s:hi('EndOfBuffer', {'guifg': s:bg})
call s:hi('ColorColumn', {'guibg': s:bg_sel})
call s:hi('Cursor',      {'guifg': s:bg_black, 'guibg': s:white_bright})
call s:hi('CursorLine',  {'guibg': s:bg_sel})
call s:hi('CursorLineNr',{'guifg': s:teal,     'gui': 'bold'})
call s:hi('LineNr',      {'guifg': s:gray})
call s:hi('SignColumn',  {'guifg': s:gray,     'guibg': s:bg})
call s:hi('Folded',      {'guifg': s:blue_soft,'guibg': s:bg_sel, 'gui': 'italic'})
call s:hi('FoldColumn',  {'guifg': s:gray,     'guibg': s:bg})
call s:hi('Conceal',     {'guifg': s:teal})
call s:hi('MatchParen',  {'guifg': s:pink,     'gui': 'bold'})
call s:hi('NonText',     {'guifg': s:bg_hl})
call s:hi('SpecialKey',  {'guifg': s:bg_hl})
call s:hi('Whitespace',  {'guifg': s:bg_hl})
call s:hi('VertSplit',   {'guifg': s:bg_hl,    'guibg': s:bg})
call s:hi('WinSeparator',{'guifg': s:bg_hl,    'guibg': s:bg})

" ---------------------------------------------------------------------------
" Selection / search
" ---------------------------------------------------------------------------
call s:hi('Visual',      {'guibg': s:bg_hl})
call s:hi('VisualNOS',   {'guibg': s:bg_hl})
call s:hi('Search',      {'guifg': s:bg_black, 'guibg': s:teal})
call s:hi('CurSearch',   {'guifg': s:bg_black, 'guibg': s:pink})
call s:hi('IncSearch',   {'guifg': s:bg_black, 'guibg': s:blue})
call s:hi('QuickFixLine',{'guifg': s:teal,     'gui': 'bold'})

" ---------------------------------------------------------------------------
" Messages / status
" ---------------------------------------------------------------------------
call s:hi('ModeMsg',     {'guifg': s:teal,     'gui': 'bold'})
call s:hi('MsgArea',     {'guifg': s:fg})
call s:hi('MsgSeparator',{'guifg': s:bg_hl})
call s:hi('ErrorMsg',    {'guifg': s:red,      'gui': 'bold'})
call s:hi('WarningMsg',  {'guifg': s:yellow})
call s:hi('InfoMsg',     {'guifg': s:blue_soft})
call s:hi('Question',    {'guifg': s:green})
call s:hi('Title',       {'guifg': s:pink,     'gui': 'bold'})

" ---------------------------------------------------------------------------
" Tabs / statusline
" ---------------------------------------------------------------------------
call s:hi('TabLine',     {'guifg': s:fg_dim,   'guibg': s:bg_panel})
call s:hi('TabLineFill', {'guibg': s:bg_panel})
call s:hi('TabLineSel',  {'guifg': s:bg_black, 'guibg': s:teal, 'gui': 'bold'})
call s:hi('StatusLine',  {'guifg': s:fg,       'guibg': s:bg_panel})
call s:hi('StatusLineNC',{'guifg': s:fg_dim,   'guibg': s:bg_panel})
call s:hi('StatusLineTerm',  {'guifg': s:fg,   'guibg': s:bg_panel})
call s:hi('StatusLineTermNC',{'guifg': s:fg_dim,'guibg': s:bg_panel})

" ---------------------------------------------------------------------------
" Pmenu / popups
" ---------------------------------------------------------------------------
call s:hi('Pmenu',       {'guifg': s:fg,       'guibg': s:bg_panel})
call s:hi('PmenuSel',    {'guifg': s:bg_black, 'guibg': s:teal, 'gui': 'bold'})
call s:hi('PmenuSbar',   {'guibg': s:bg_sel})
call s:hi('PmenuThumb',  {'guibg': s:teal_dark})
call s:hi('WildMenu',    {'guifg': s:bg_black, 'guibg': s:teal})

" ---------------------------------------------------------------------------
" Diff
" ---------------------------------------------------------------------------
call s:hi('DiffAdd',     {'guifg': s:green,    'guibg': s:bg_panel})
call s:hi('DiffChange',  {'guifg': s:yellow,   'guibg': s:bg_panel})
call s:hi('DiffDelete',  {'guifg': s:red,      'guibg': s:bg_panel})
call s:hi('DiffText',    {'guifg': s:bg_black, 'guibg': s:teal})
call s:hi('DiffAdded',   {'guifg': s:green})
call s:hi('DiffRemoved', {'guifg': s:red})

" ---------------------------------------------------------------------------
" Spelling / diagnostics / misc
" ---------------------------------------------------------------------------
call s:hi('SpellBad',    {'guisp': s:red,      'gui': 'undercurl'})
call s:hi('SpellCap',    {'guisp': s:yellow,   'gui': 'undercurl'})
call s:hi('SpellLocal',  {'guisp': s:blue,     'gui': 'undercurl'})
call s:hi('SpellRare',   {'guisp': s:pink,     'gui': 'undercurl'})
call s:hi('Directory',   {'guifg': s:blue_soft})
call s:hi('MoreMsg',     {'guifg': s:green})
call s:hi('CursorIM',    {'guifg': s:bg_black, 'guibg': s:white_bright})
call s:hi('Underlined',  {'guifg': s:blue_soft,'gui': 'underline'})

" LSP / diagnostics
call s:hi('DiagnosticError',  {'guifg': s:red})
call s:hi('DiagnosticWarn',   {'guifg': s:yellow})
call s:hi('DiagnosticInfo',   {'guifg': s:blue_soft})
call s:hi('DiagnosticHint',   {'guifg': s:lavender})
call s:hi('DiagnosticOk',     {'guifg': s:green})
call s:hi('DiagnosticUnderlineError', {'guisp': s:red,    'gui': 'undercurl'})
call s:hi('DiagnosticUnderlineWarn',  {'guisp': s:yellow, 'gui': 'undercurl'})
call s:hi('DiagnosticUnderlineInfo',  {'guisp': s:blue_soft,'gui': 'undercurl'})
call s:hi('DiagnosticUnderlineHint',  {'guisp': s:lavender,'gui': 'undercurl'})
call s:hi('DiagnosticVirtualTextError', {'guifg': s:red})
call s:hi('DiagnosticVirtualTextWarn',  {'guifg': s:yellow})
call s:hi('DiagnosticVirtualTextInfo',  {'guifg': s:blue_soft})
call s:hi('DiagnosticVirtualTextHint',  {'guifg': s:lavender})
call s:hi('DiagnosticFloatingError',    {'guifg': s:red})
call s:hi('DiagnosticFloatingWarn',     {'guifg': s:yellow})
call s:hi('DiagnosticFloatingInfo',     {'guifg': s:blue_soft})
call s:hi('DiagnosticFloatingHint',     {'guifg': s:lavender})
call s:hi('DiagnosticSignError',        {'guifg': s:red})
call s:hi('DiagnosticSignWarn',         {'guifg': s:yellow})
call s:hi('DiagnosticSignInfo',         {'guifg': s:blue_soft})
call s:hi('DiagnosticSignHint',         {'guifg': s:lavender})

" ---------------------------------------------------------------------------
" Syntax (treesitter + classic)
" ---------------------------------------------------------------------------
call s:hi('Comment',     {'guifg': s:comment,  'gui': 'italic'})
call s:hi('Constant',    {'guifg': s:blue})
call s:hi('String',      {'guifg': s:blue})
call s:hi('Character',   {'guifg': s:blue})
call s:hi('Number',      {'guifg': s:blue})
call s:hi('Boolean',     {'guifg': s:blue})
call s:hi('Float',       {'guifg': s:blue})
call s:hi('Identifier',  {'guifg': s:teal})
call s:hi('Function',    {'guifg': s:lavender})
call s:hi('Statement',   {'guifg': s:lavender})
call s:hi('Conditional', {'guifg': s:lavender, 'gui': 'italic'})
call s:hi('Repeat',      {'guifg': s:lavender})
call s:hi('Label',       {'guifg': s:lavender})
call s:hi('Operator',    {'guifg': s:pink})
call s:hi('Keyword',     {'guifg': s:lavender})
call s:hi('Exception',   {'guifg': s:lavender})
call s:hi('PreProc',     {'guifg': s:pink})
call s:hi('Include',     {'guifg': s:pink})
call s:hi('Define',      {'guifg': s:pink})
call s:hi('Macro',       {'guifg': s:pink})
call s:hi('PreCondit',   {'guifg': s:pink})
call s:hi('Type',        {'guifg': s:green})
call s:hi('StorageClass',{'guifg': s:green})
call s:hi('Structure',   {'guifg': s:green})
call s:hi('Typedef',     {'guifg': s:green})
call s:hi('Special',     {'guifg': s:pink})
call s:hi('SpecialChar', {'guifg': s:pink})
call s:hi('Tag',         {'guifg': s:teal})
call s:hi('Delimiter',   {'guifg': s:gray})
call s:hi('SpecialComment', {'guifg': s:comment, 'gui': 'italic'})
call s:hi('Debug',       {'guifg': s:pink})
call s:hi('Underline',   {'gui': 'underline'})
call s:hi('Ignore',      {'guifg': s:bg_hl})
call s:hi('Error',       {'guifg': s:red})
call s:hi('Todo',        {'guifg': s:bg_black, 'guibg': s:yellow, 'gui': 'bold'})

" ---------------------------------------------------------------------------
" Treesitter highlight groups
" ---------------------------------------------------------------------------
call s:hi('@comment',                 {'guifg': s:comment,  'gui': 'italic'})
call s:hi('@error',                   {'guifg': s:red})
call s:hi('@punctuation.delimiter',   {'guifg': s:gray})
call s:hi('@punctuation.bracket',     {'guifg': s:gray})
call s:hi('@punctuation.special',     {'guifg': s:pink})

" literals
call s:hi('@string',                  {'guifg': s:blue})
call s:hi('@string.regexp',           {'guifg': s:pink})
call s:hi('@string.escape',           {'guifg': s:pink})
call s:hi('@string.special',          {'guifg': s:pink})
call s:hi('@string.symbol',           {'guifg': s:pink})
call s:hi('@character',               {'guifg': s:blue})
call s:hi('@character.special',       {'guifg': s:pink})
call s:hi('@number',                  {'guifg': s:blue})
call s:hi('@number.float',            {'guifg': s:blue})
call s:hi('@boolean',                 {'guifg': s:blue})
call s:hi('@constant',                {'guifg': s:blue})
call s:hi('@constant.builtin',        {'guifg': s:teal})
call s:hi('@constant.macro',          {'guifg': s:pink})

" names
call s:hi('@variable',                {'guifg': s:fg})
call s:hi('@variable.builtin',        {'guifg': s:teal})
call s:hi('@variable.parameter',      {'guifg': s:teal})
call s:hi('@variable.member',         {'guifg': s:cyan})
call s:hi('@variable.member.key',     {'guifg': s:teal})
call s:hi('@property',                {'guifg': s:cyan})
call s:hi('@field',                   {'guifg': s:cyan})
call s:hi('@function',                {'guifg': s:lavender})
call s:hi('@function.call',           {'guifg': s:lavender})
call s:hi('@function.builtin',        {'guifg': s:blue_soft})
call s:hi('@function.macro',          {'guifg': s:pink})
call s:hi('@function.method',         {'guifg': s:lavender})
call s:hi('@function.method.call',    {'guifg': s:lavender})
call s:hi('@constructor',             {'guifg': s:green})
call s:hi('@parameter',               {'guifg': s:teal})
call s:hi('@method',                  {'guifg': s:lavender})
call s:hi('@method.call',             {'guifg': s:lavender})
call s:hi('@label',                   {'guifg': s:pink})

" keywords
call s:hi('@keyword',                 {'guifg': s:lavender})
call s:hi('@keyword.function',        {'guifg': s:lavender})
call s:hi('@keyword.return',          {'guifg': s:lavender})
call s:hi('@keyword.operator',        {'guifg': s:pink})
call s:hi('@keyword.conditional',     {'guifg': s:lavender, 'gui': 'italic'})
call s:hi('@keyword.repeat',          {'guifg': s:lavender})
call s:hi('@keyword.debug',           {'guifg': s:pink})
call s:hi('@keyword.exception',       {'guifg': s:lavender})
call s:hi('@keyword.import',          {'guifg': s:pink})
call s:hi('@keyword.type',            {'guifg': s:green})
call s:hi('@keyword.storage',         {'guifg': s:green})
call s:hi('@conditional',             {'guifg': s:lavender, 'gui': 'italic'})
call s:hi('@repeat',                  {'guifg': s:lavender})
call s:hi('@debug',                   {'guifg': s:pink})
call s:hi('@exception',               {'guifg': s:lavender})
call s:hi('@include',                 {'guifg': s:pink})
call s:hi('@define',                  {'guifg': s:pink})
call s:hi('@preproc',                 {'guifg': s:pink})
call s:hi('@storageclass',            {'guifg': s:green})
call s:hi('@storageclass.lifetime',   {'guifg': s:blue_soft})

" types
call s:hi('@type',                    {'guifg': s:green})
call s:hi('@type.builtin',            {'guifg': s:green})
call s:hi('@type.definition',         {'guifg': s:green})
call s:hi('@type.qualifier',          {'guifg': s:green})
call s:hi('@type.property',           {'guifg': s:cyan})
call s:hi('@namespace',               {'guifg': s:green})
call s:hi('@module',                  {'guifg': s:green})

" operators / punctuation
call s:hi('@operator',                {'guifg': s:pink})
call s:hi('@punctuation.delimiter',   {'guifg': s:gray})
call s:hi('@punctuation.bracket',     {'guifg': s:gray})
call s:hi('@punctuation.special',     {'guifg': s:pink})

" tags
call s:hi('@tag',                     {'guifg': s:teal})
call s:hi('@tag.attribute',           {'guifg': s:blue})
call s:hi('@tag.delimiter',           {'guifg': s:gray})
call s:hi('@tag.attribute.tsx',       {'guifg': s:blue})
call s:hi('@tag.tsx',                 {'guifg': s:teal})

" markup
call s:hi('@markup.heading',          {'guifg': s:teal, 'gui': 'bold'})
call s:hi('@markup.heading.1',        {'guifg': s:teal, 'gui': 'bold'})
call s:hi('@markup.heading.2',        {'guifg': s:blue_soft, 'gui': 'bold'})
call s:hi('@markup.heading.3',        {'guifg': s:green, 'gui': 'bold'})
call s:hi('@markup.heading.4',        {'guifg': s:yellow, 'gui': 'bold'})
call s:hi('@markup.heading.5',        {'guifg': s:pink, 'gui': 'bold'})
call s:hi('@markup.heading.6',        {'guifg': s:purple, 'gui': 'bold'})
call s:hi('@markup.italic',           {'gui': 'italic'})
call s:hi('@markup.bold',             {'gui': 'bold'})
call s:hi('@markup.strikethrough',    {'gui': 'strikethrough'})
call s:hi('@markup.underline',        {'gui': 'underline'})
call s:hi('@markup.link',             {'guifg': s:blue_soft, 'gui': 'underline'})
call s:hi('@markup.link.label',       {'guifg': s:pink})
call s:hi('@markup.link.url',         {'guifg': s:blue})
call s:hi('@markup.raw',              {'guifg': s:green})
call s:hi('@markup.raw.block',        {'guifg': s:green})
call s:hi('@markup.list',             {'guifg': s:teal})
call s:hi('@markup.list.checked',     {'guifg': s:green})
call s:hi('@markup.list.unchecked',   {'guifg': s:gray})
call s:hi('@markup.quote',            {'guifg': s:comment, 'gui': 'italic'})
call s:hi('@markup.code',             {'guifg': s:green})
call s:hi('@markup.math',             {'guifg': s:blue})
call s:hi('@markup.environment',      {'guifg': s:pink})
call s:hi('@markup.strong',           {'gui': 'bold'})
call s:hi('@markup.emphasis',         {'gui': 'italic'})
call s:hi('@markup.underline.link',   {'guifg': s:blue_soft, 'gui': 'underline'})
call s:hi('@markup.link.url.scheme',  {'guifg': s:pink})

" text
call s:hi('@text',                    {'guifg': s:fg})
call s:hi('@text.strong',             {'gui': 'bold'})
call s:hi('@text.emphasis',           {'gui': 'italic'})
call s:hi('@text.underline',          {'gui': 'underline'})
call s:hi('@text.strike',             {'gui': 'strikethrough'})
call s:hi('@text.title',              {'guifg': s:teal, 'gui': 'bold'})
call s:hi('@text.literal',            {'guifg': s:green})
call s:hi('@text.uri',                {'guifg': s:blue, 'gui': 'underline'})
call s:hi('@text.math',               {'guifg': s:blue})
call s:hi('@text.environment',        {'guifg': s:pink})
call s:hi('@text.reference',          {'guifg': s:pink})
call s:hi('@text.todo',               {'guifg': s:bg_black, 'guibg': s:yellow, 'gui': 'bold'})
call s:hi('@text.note',               {'guifg': s:blue_soft})
call s:hi('@text.warning',            {'guifg': s:yellow})
call s:hi('@text.danger',             {'guifg': s:red})
call s:hi('@text.diff.add',           {'guifg': s:green})
call s:hi('@text.diff.delete',        {'guifg': s:red})

" ---------------------------------------------------------------------------
" Terminal colors (matches Warp Cyber Wave exactly)
" ---------------------------------------------------------------------------
let g:terminal_color_0  = "#616161"
let g:terminal_color_1  = "#ff8272"
let g:terminal_color_2  = "#b4fa72"
let g:terminal_color_3  = "#fefdc2"
let g:terminal_color_4  = "#a5d5fe"
let g:terminal_color_5  = "#ff8ffd"
let g:terminal_color_6  = "#d0d1fe"
let g:terminal_color_7  = "#f1f1f1"
let g:terminal_color_8  = "#8e8e8e"
let g:terminal_color_9  = "#ffc4bd"
let g:terminal_color_10 = "#d6fcb9"
let g:terminal_color_11 = "#fefdd5"
let g:terminal_color_12 = "#c1e3fe"
let g:terminal_color_13 = "#ffb1fe"
let g:terminal_color_14 = "#e5e6fe"
let g:terminal_color_15 = "#feffff"

" Clean up helper
delfunction s:hi

-- nvim/lua/themes/init.lua


local M = {}

M.config = {
  transparent = true,
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

local function hl(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

function M.load()
    -- wipe existing highlights and reset syntax
    if vim.g.colors_name then
        vim.cmd("hi clear")
    end
    if vim.fn.exists("syntax_on") then
        vim.cmd("syntax reset")
    end

    vim.o.termguicolors = true
    vim.g.colors_name = "elysian"

    local ok, palette = pcall(require, "themes.active")
    if not ok then
        vim.notify("themes: could not load lua/themes/active.lua palette", vim.log.levels.ERROR)
        return
    end
    local c = palette.colors

    local bg = M.config.transparent and "NONE" or c.BG

    ----------------------------------------------------------------------
    -- Editor UI
    ----------------------------------------------------------------------
    hl("Normal",       { fg = c.FG, bg = bg })
    hl("NormalNC",     { fg = c.FG, bg = bg })
    hl("NormalFloat",  { fg = c.FG, bg = M.config.transparent and "NONE" or c.BG_POPUP })
    hl("FloatBorder",  { fg = c.BORDER, bg = M.config.transparent and "NONE" or c.BG_POPUP })
    hl("FloatTitle",   { fg = c.ACCENT_LOW, bg = M.config.transparent and "NONE" or c.BG_POPUP })

    hl("Cursor",       { fg = c.BG, bg = c.FG })
    hl("CursorLine",   { bg = c.BG_HIGHLIGHT })
    hl("CursorLineNr", { fg = c.ACCENT_LOW, bold = true })
    hl("CursorColumn", { bg = c.BG_HIGHLIGHT })
    hl("ColorColumn",  { bg = c.BG_STRIPE })

    hl("LineNr",       { fg = c.FG_GHOST })
    hl("SignColumn",   { fg = c.FG_GHOST, bg = bg })
    hl("FoldColumn",   { fg = c.FG_GHOST, bg = bg })
    hl("Folded",       { fg = c.FG_MUTED, bg = c.BG_OVERLAY })

    hl("VertSplit",    { fg = c.BORDER })
    hl("WinSeparator", { fg = c.BORDER })
    hl("EndOfBuffer",  { fg = bg, bg = bg })

    hl("Visual",       { bg = c.DARK7 })
    hl("VisualNOS",    { bg = c.DARK7 })

    hl("Search",       { fg = c.BG, bg = c.WARNING_LOW })
    hl("IncSearch",    { fg = c.BG, bg = c.URGENT })
    hl("CurSearch",    { fg = c.BG, bg = c.URGENT })

    hl("Pmenu",        { fg = c.FG_DIM, bg = c.BG_POPUP })
    hl("PmenuSel",     { fg = c.FG, bg = c.BG_SELECTED, bold = true })
    hl("PmenuSbar",    { bg = c.BG_OVERLAY })
    hl("PmenuThumb",   { bg = c.DARK5 })
    hl("PmenuKind",    { fg = c.SECONDARY_MUTED, bg = c.BG_POPUP })
    hl("PmenuExtra",   { fg = c.FG_DISABLED, bg = c.BG_POPUP })

    hl("StatusLine",   { fg = c.FG_DIM, bg = c.BG_DARK })
    hl("StatusLineNC", { fg = c.FG_GHOST, bg = c.BG_DARK })
    hl("TabLine",      { fg = c.FG_MUTED, bg = c.BG_DARK })
    hl("TabLineSel",   { fg = c.FG, bg = c.BG_ACTIVE, bold = true })
    hl("TabLineFill",  { bg = c.BG_DARK })

    hl("MatchParen",   { fg = c.WARNING, bold = true, underline = true })
    hl("Whitespace",   { fg = c.DARK6 })
    hl("NonText",      { fg = c.DARK6 })
    hl("SpecialKey",   { fg = c.DARK6 })
    hl("Title",        { fg = c.ACCENT_LOW, bold = true })
    hl("Directory",    { fg = c.SECONDARY })
    hl("Question",     { fg = c.SUCCESS })
    hl("ModeMsg",      { fg = c.FG_DIM })
    hl("MoreMsg",      { fg = c.SUCCESS })
    hl("WildMenu",     { fg = c.BG, bg = c.ACCENT_LOW })

    hl("ErrorMsg",     { fg = c.ERROR })
    hl("WarningMsg",   { fg = c.WARNING })

    ----------------------------------------------------------------------
    -- Diff / VCS
    ----------------------------------------------------------------------
    hl("DiffAdd",    { fg = c.VCS_ADDED,    bg = c.BG_DARK })
    hl("DiffChange", { fg = c.VCS_MODIFIED, bg = c.BG_DARK })
    hl("DiffDelete", { fg = c.VCS_DELETED,  bg = c.BG_DARK })
    hl("DiffText",   { fg = c.FG, bg = c.ACCENT })

    hl("GitSignsAdd",    { fg = c.VCS_ADDED })
    hl("GitSignsChange", { fg = c.VCS_MODIFIED })
    hl("GitSignsDelete", { fg = c.VCS_DELETED })

    ----------------------------------------------------------------------
    -- Diagnostics / LSP
    ----------------------------------------------------------------------
    hl("DiagnosticError", { fg = c.ERROR })
    hl("DiagnosticWarn",  { fg = c.WARNING })
    hl("DiagnosticInfo",  { fg = c.INFO })
    hl("DiagnosticHint",  { fg = c.SECONDARY_MUTED })
    hl("DiagnosticOk",    { fg = c.SUCCESS })

    hl("DiagnosticUnderlineError", { undercurl = true, sp = c.ERROR })
    hl("DiagnosticUnderlineWarn",  { undercurl = true, sp = c.WARNING })
    hl("DiagnosticUnderlineInfo",  { undercurl = true, sp = c.INFO })
    hl("DiagnosticUnderlineHint",  { undercurl = true, sp = c.SECONDARY_MUTED })

    hl("DiagnosticVirtualTextError", { fg = c.ERROR_SUBTLE,  bg = M.config.transparent and "NONE" or c.ERROR_SURFACE })
    hl("DiagnosticVirtualTextWarn",  { fg = c.WARNING_SUBTLE, bg = "NONE" })
    hl("DiagnosticVirtualTextInfo",  { fg = c.INFO_SUBTLE,    bg = "NONE" })
    hl("DiagnosticVirtualTextHint",  { fg = c.SECONDARY_MUTED, bg = "NONE" })

    hl("LspReferenceText",  { bg = c.BG_HOVER })
    hl("LspReferenceRead",  { bg = c.BG_HOVER })
    hl("LspReferenceWrite", { bg = c.BG_HOVER, underline = true })
    hl("LspSignatureActiveParameter", { fg = c.WARNING_LOW, bold = true })
    hl("LspInlayHint", { fg = c.FG_GHOST, bg = M.config.transparent and "NONE" or c.BG_OVERLAY })

    ----------------------------------------------------------------------
    -- Base syntax groups
    ----------------------------------------------------------------------
    hl("Comment",    { fg = c.FG_HINT, italic = true })

    hl("Constant",   { fg = c.TERTIARY_SUBTLE })
    hl("String",     { fg = c.SUCCESS_MUTED })
    hl("Character",  { fg = c.SUCCESS_MUTED })
    hl("Number",     { fg = c.TERTIARY_MUTED })
    hl("Boolean",    { fg = c.TERTIARY_MUTED })
    hl("Float",      { fg = c.TERTIARY_MUTED })

    hl("Identifier", { fg = c.ANSI_RED })
    hl("Function",   { fg = c.ANSI_BLUE })

    hl("Statement",  { fg = c.TERTIARY })
    hl("Conditional",{ fg = c.TERTIARY })
    hl("Repeat",     { fg = c.TERTIARY })
    hl("Label",      { fg = c.TERTIARY })
    hl("Operator",   { fg = c.FG_LIGHT })
    hl("Keyword",    { fg = c.TERTIARY, italic = true })
    hl("Exception",  { fg = c.ERROR })

    hl("PreProc",    { fg = c.SECONDARY_MUTED })
    hl("Include",    { fg = c.TERTIARY })
    hl("Define",     { fg = c.SECONDARY_MUTED })
    hl("Macro",      { fg = c.SECONDARY_MUTED })
    hl("PreCondit",  { fg = c.SECONDARY_MUTED })

    hl("Type",       { fg = c.WARNING_SUBTLE })
    hl("StorageClass", { fg = c.WARNING_SUBTLE })
    hl("Structure",  { fg = c.WARNING_SUBTLE })
    hl("Typedef",    { fg = c.WARNING_SUBTLE })

    hl("Special",    { fg = c.SECONDARY })
    hl("SpecialChar",{ fg = c.SECONDARY })
    hl("Tag",        { fg = c.ANSI_RED })
    hl("Delimiter",  { fg = c.FG_SUBTLE })
    hl("SpecialComment", { fg = c.FG_HINT, italic = true })
    hl("Underlined", { underline = true })
    hl("Ignore",     { fg = c.FG_DISABLED })
    hl("Todo",       { fg = c.BG, bg = c.WARNING, bold = true })

    ----------------------------------------------------------------------
    -- Treesitter (@ groups) - only what differs from the base groups above
    ----------------------------------------------------------------------
    hl("@variable",          { fg = c.FG_DARK })
    hl("@variable.builtin",  { fg = c.ANSI_RED, italic = true })
    hl("@variable.parameter",{ fg = c.URGENT })
    hl("@variable.member",   { fg = c.ANSI_CYAN })

    hl("@property",          { fg = c.ANSI_CYAN })
    hl("@field",              { fg = c.ANSI_CYAN })

    hl("@function",          { fg = c.ANSI_BLUE })
    hl("@function.builtin",  { fg = c.SECONDARY_MUTED })
    hl("@function.call",     { fg = c.ANSI_BLUE })
    hl("@method",            { fg = c.ANSI_BLUE })
    hl("@method.call",       { fg = c.ANSI_BLUE })
    hl("@constructor",       { fg = c.WARNING_SUBTLE })

    hl("@keyword",           { fg = c.TERTIARY, italic = true })
    hl("@keyword.function",  { fg = c.TERTIARY, italic = true })
    hl("@keyword.return",    { fg = c.TERTIARY, italic = true })
    hl("@keyword.operator",  { fg = c.TERTIARY })
    hl("@conditional",       { fg = c.TERTIARY })

    hl("@type",              { fg = c.WARNING_SUBTLE })
    hl("@type.builtin",      { fg = c.WARNING_SUBTLE, italic = true })
    hl("@attribute",         { fg = c.SECONDARY_MUTED })
    hl("@namespace",         { fg = c.WARNING_SUBTLE })

    hl("@punctuation.bracket",  { fg = c.FG_SUBTLE })
    hl("@punctuation.delimiter",{ fg = c.FG_SUBTLE })
    hl("@punctuation.special",  { fg = c.SECONDARY })

    hl("@string",            { fg = c.SUCCESS_MUTED })
    hl("@string.escape",     { fg = c.SECONDARY })
    hl("@string.special",    { fg = c.SECONDARY })
    hl("@number",            { fg = c.TERTIARY_MUTED })
    hl("@boolean",           { fg = c.TERTIARY_MUTED })
    hl("@constant",          { fg = c.TERTIARY_SUBTLE })
    hl("@constant.builtin",  { fg = c.TERTIARY_SUBTLE, italic = true })

    hl("@comment",           { fg = c.FG_HINT, italic = true })
    hl("@tag",               { fg = c.ANSI_RED })
    hl("@tag.attribute",     { fg = c.WARNING_SUBTLE })
    hl("@tag.delimiter",     { fg = c.FG_SUBTLE })

    hl("@markup.heading",    { fg = c.ACCENT_LOW, bold = true })
    hl("@markup.strong",     { bold = true })
    hl("@markup.italic",     { italic = true })
    hl("@markup.link",       { fg = c.SECONDARY, underline = true })
    hl("@markup.link.url",   { fg = c.SECONDARY_MUTED, underline = true })

    ----------------------------------------------------------------------
    -- Popular plugins
    ----------------------------------------------------------------------
    -- Telescope
    hl("TelescopeNormal",    { fg = c.FG_DIM, bg = M.config.transparent and "NONE" or c.BG_POPUP })
    hl("TelescopeBorder",    { fg = c.BORDER, bg = M.config.transparent and "NONE" or c.BG_POPUP })
    hl("TelescopePromptNormal", { fg = c.FG, bg = M.config.transparent and "NONE" or c.BG_FOCUSED })
    hl("TelescopePromptBorder", { fg = c.BORDER, bg = M.config.transparent and "NONE" or c.BG_FOCUSED })
    hl("TelescopeSelection", { bg = c.BG_SELECTED })
    hl("TelescopeMatching",  { fg = c.WARNING, bold = true })

    -- nvim-cmp
    hl("CmpItemAbbr",           { fg = c.FG_DIM })
    hl("CmpItemAbbrMatch",      { fg = c.ACCENT_LOW, bold = true })
    hl("CmpItemAbbrDeprecated", { fg = c.FG_DISABLED, strikethrough = true })
    hl("CmpItemKind",           { fg = c.SECONDARY_MUTED })
    hl("CmpItemMenu",           { fg = c.FG_GHOST })

    -- which-key
    hl("WhichKey",          { fg = c.ANSI_BLUE })
    hl("WhichKeyGroup",     { fg = c.TERTIARY })
    hl("WhichKeyDesc",      { fg = c.FG_DIM })
    hl("WhichKeySeparator", { fg = c.FG_GHOST })

    -- indent-blankline
    hl("IblIndent", { fg = c.DARK7 })
    hl("IblScope",  { fg = c.DARK5 })

    -- NvimTree / neo-tree
    hl("NvimTreeNormal",     { fg = c.FG_DIM, bg = M.config.transparent and "NONE" or c.BG_DARK })
    hl("NvimTreeFolderIcon", { fg = c.SECONDARY })
    hl("NvimTreeFolderName", { fg = c.FG_DIM })
    hl("NvimTreeOpenedFolderName", { fg = c.ACCENT_LOW })
    hl("NvimTreeRootFolder", { fg = c.TERTIARY, bold = true })
    hl("NvimTreeIndentMarker", { fg = c.DARK7 })
    hl("NvimTreeGitDirty",   { fg = c.VCS_MODIFIED })
    hl("NvimTreeGitNew",     { fg = c.VCS_ADDED })
    hl("NvimTreeGitDeleted", { fg = c.VCS_DELETED })
end

return M

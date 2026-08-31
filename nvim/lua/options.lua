-- nvim/lua/options.lua


local opt = vim.opt

-- Line numbers
opt.number          = true
opt.relativenumber  = true
opt.numberwidth     = 5

-- Tabs / indentation
opt.expandtab   = true
opt.tabstop     = 4
opt.softtabstop = 4
opt.shiftwidth  = 4
opt.smartindent = true

-- Appearance
opt.termguicolors   = true
opt.cursorline      = true
opt.laststatus      = 2
opt.showmode        = false   -- lualine handles this
opt.signcolumn      = "yes"

-- Indentation markers
opt.list        = true
opt.listchars   = { leadmultispace = "¦   ", trail = "·" }

-- Folding
opt.foldmethod  = "indent"
opt.foldlevel   = 20

-- Encoding & file format
opt.encoding    = "utf-8"
opt.fileformat  = "unix"

-- Wrapping
opt.textwidth   = 90
opt.wrap        = true

-- No swap files
opt.swapfile    = false

-- Window management
opt.splitbelow = true

-- Remove trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    callback = function()
        local pos = vim.api.nvim_win_get_cursor(0)
        vim.cmd([[%s/\s\+$//e]])
        vim.api.nvim_win_set_cursor(0, pos)
    end,
})

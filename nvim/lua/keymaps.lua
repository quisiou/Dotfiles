-- nvim/lua/keymaps.lua


-- Set space as leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

--- Move current line up / down -----------------------------------------------
map("n",    "<leader>k",    ":m .-2<CR>==",         { desc = "Move line up" })
map("n",    "<leader>j",    ":m .+1<CR>==",         { desc = "Move line down" })

-- Visual mode (preserves visual block selection and auto-indents)
map("v",    "K",            ":m '<-2<CR>gv=gv",     { desc = "Move selection up" })
map("v",    "J",            ":m '>+1<CR>gv=gv",     { desc = "Move selection down" })

--- Duplicate line / selection -----------------------------------------------
map("n",    "<leader>l",    ":t.<CR>",              { desc = "Duplicate line down" })
map("n",    "<leader>h",    ":t-1<CR>",             { desc = "Duplicate line up" })
map("v",    "<leader>l",    ":t'><CR>gv",           { desc = "Duplicate selection down" })
map("v",    "<leader>h",    ":t'<-1<CR>gv",         { desc = "Duplicate selection up" })

--- Selection & Clipboard -----------------------------------------------------
map("n",    "<leader>a",    "ggVG",                 { desc = "Select all" })
map("v",    "<leader>y",    '"+y',                  { desc = "Yank to system clipboard" })

--- Indent / un-indent --------------------------------------------------------
map("n",    "<Tab>",        ">>",                   { desc = "Indent line" })
map("n",    "<S-Tab>",      "<<",                   { desc = "Un-indent line" })
map("v",    "<Tab>",        ">gv",                  { desc = "Indent selection" })
map("v",    "<S-Tab>",      "<gv",                  { desc = "Un-indent selection" })

-- Toggle comments ------------------------------------------------------------
map("n",    "<C-.>",        "gcc",                  { remap = true, desc = "Toggle line comment" })
map("v",    "<C-.>",        "gc",                   { remap = true, desc = "Toggle line comment" })
map("i",    "<C-.>",        "<Esc>gccgi",           { remap = true, desc = "Toggle line comment" })

--- Window navigation ---------------------------------------------------------
-- Standard pane navigation (frees up <leader>w for saving)
map("n",    "<C-h>",        "<C-w>h",               { desc = "Focus left window" })
map("n",    "<C-j>",        "<C-w>j",               { desc = "Focus bottom window" })
map("n",    "<C-k>",        "<C-w>k",               { desc = "Focus top window" })
map("n",    "<C-l>",        "<C-w>l",               { desc = "Focus right window" })

map("n",    "<leader>w",    "<cmd>w<CR>",           { desc = "Save file" })
map("t",    "<C-h>",        "<C-\\><C-n><C-w>h",    { desc = "Focus left (terminal)" })

--- Terminal ------------------------------------------------------------------
map("n",    "<leader>t",    ":term<CR>",            { desc = "Open terminal" })

--- Search & Grep ------------------------------------------------------------
-- Clear highlights with Esc
map("n",    "<Esc>",        "<cmd>nohlsearch<CR>",  { desc = "Clear search highlight" })

-- Project search with slash escaping
map("n", "<leader>F", function()
    local pattern = vim.fn.input("Search pattern: ")
    if pattern ~= "" then
        local escaped = vim.fn.escape(pattern, "/")
        vim.cmd("vimgrep /" .. escaped .. "/gj **/*")
        vim.cmd("copen")
    end
end, { desc = "Grep in project" })

--- Quickfix list keybinds
vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    callback = function()
        map("n",    "<Esc>",    ":cclose<CR>",  { buffer = true, desc = "Close quickfix" })
        map("n",    "l",        "<CR><C-w>p",   { buffer = true, desc = "Open entry and return" })
    end,
})

-- nvim/lua/plugins/lualine.lua


return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    config = function()
        local ok, palette = pcall(require, "themes.active")
        local c = ok and palette.colors or nil

        local elysian_theme = nil
        if c then
            elysian_theme = {
                normal = {
                    a = { fg = c.BG, bg = c.ACCENT_LOW, gui = "bold" },
                    b = { fg = c.FG_DIM, bg = c.BG_ACTIVE },
                    c = { fg = c.FG_MUTED, bg = c.BG_DARK },
                },
                insert  = { a = { fg = c.BG, bg = c.SUCCESS_MUTED, gui = "bold" } },
                visual  = { a = { fg = c.BG, bg = c.TERTIARY, gui = "bold" } },
                replace = { a = { fg = c.BG, bg = c.ERROR, gui = "bold" } },
                command = { a = { fg = c.BG, bg = c.WARNING, gui = "bold" } },
                inactive = {
                    a = { fg = c.FG_GHOST, bg = c.BG_DARK },
                    b = { fg = c.FG_GHOST, bg = c.BG_DARK },
                    c = { fg = c.FG_GHOST, bg = c.BG_DARK },
                },
            }
        end

        require("lualine").setup({
            options = {
                theme = elysian_theme or "auto",
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                globalstatus = true, -- one statusline for the whole window, not per-split
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff" },
                lualine_c = {
                    { "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = " " } },
                    { "filename", path = 1 }, -- relative path, since you often browse via Neo-tree
                },
                lualine_x = { "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
        })
    end,
}

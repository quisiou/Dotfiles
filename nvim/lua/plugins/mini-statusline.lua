-- nvim/lua/plugins/mini-statusline.lua


return {
    "nvim-mini/mini.statusline",
    event = "VeryLazy",
    config = function()
        vim.o.laststatus = 3 -- one statusline for the whole window (lualine's globalstatus)

        local ok, palette = pcall(require, "themes.active")
        local c = ok and palette.colors or nil

        if c then
            local set_hl = vim.api.nvim_set_hl
            set_hl(0, "MiniStatuslineModeNormal", { fg = c.BG, bg = c.ACCENT_LOW, bold = true })
            set_hl(0, "MiniStatuslineModeInsert", { fg = c.BG, bg = c.SUCCESS_MUTED, bold = true })
            set_hl(0, "MiniStatuslineModeVisual", { fg = c.BG, bg = c.TERTIARY, bold = true })
            set_hl(0, "MiniStatuslineModeReplace", { fg = c.BG, bg = c.ERROR, bold = true })
            set_hl(0, "MiniStatuslineModeCommand", { fg = c.BG, bg = c.WARNING, bold = true })
            set_hl(0, "MiniStatuslineModeOther", { fg = c.BG, bg = c.ACCENT_LOW, bold = true })
            set_hl(0, "MiniStatuslineDevinfo", { fg = c.FG_DARK, bg = c.BG_ACTIVE })
            set_hl(0, "MiniStatuslineFilename", { fg = c.FG_DIM, bg = c.BG_DARK })
            set_hl(0, "MiniStatuslineFileinfo", { fg = c.FG_DIM, bg = c.BG_DARK })
            set_hl(0, "MiniStatuslineInactive", { fg = c.FG_GHOST, bg = c.BG_DARK })
        end

        local statusline = require("mini.statusline")

        -- match your old lualine diagnostic symbols exactly
        local diagnostic_icons = { ERROR = " ", WARN = " ", INFO = " ", HINT = " " }
        local function diagnostics()
            if vim.bo.buftype ~= "" then return "" end
            local out = {}
            for severity, icon in pairs(diagnostic_icons) do
                local n = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity[severity] })
                if n > 0 then table.insert(out, icon .. n) end
            end
            return table.concat(out, " ")
        end

        statusline.setup({
            use_icons = true, -- picks up mini.icons, which you already have set up
            content = {
                active = function()
                    local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })
                    mode = mode:upper()
                    local git = statusline.section_git({ trunc_width = 75 })
                    local diff = statusline.section_diff({ trunc_width = 75 })
                    local filename = statusline.section_filename({ trunc_width = 140 })
                    local fileinfo = statusline.section_fileinfo({ trunc_width = 120 })
                    local location = statusline.section_location({ trunc_width = 75 })

                    return statusline.combine_groups({
                        { hl = mode_hl, strings = { mode } },
                        { hl = "MiniStatuslineDevinfo", strings = { git, diff } },
                        "%<", -- truncation point
                        { hl = "MiniStatuslineFilename", strings = { diagnostics(), filename } },
                        "%=", -- right-align everything after this
                        { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
                        { hl = mode_hl, strings = { location } },
                    })
                end,
            },
        })
    end,
}

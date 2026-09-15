-- nvim/lua/plugins/mini.lua


return {
    -- Icons
    {
        "nvim-mini/mini.icons",
        lazy = false,   -- must be ready before neo-tree/lualine ask for icons
        priority = 1000, -- load before other non-lazy plugins that consume icons
        config = function()
            require("mini.icons").setup()
            -- makes any plugin that only knows nvim-web-devicons work transparently
            require("mini.icons").mock_nvim_web_devicons()
        end,
    },

    -- Color highlighting (rgb, hex, hsl, ...)
    {
        "nvim-mini/mini.hipatterns",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local hipatterns = require("mini.hipatterns")

            -- #rrggbb
            local hex_color = hipatterns.gen_highlighter.hex_color({ style = "full" })

            -- #rgb -> expand to #rrggbb and reuse the same color-group machinery
            local short_hex_group = function(_, match)
                local r, g, b = match:sub(2, 2), match:sub(3, 3), match:sub(4, 4)
                local hex = "#" .. r .. r .. g .. g .. b .. b
                return MiniHipatterns.compute_hex_color_group(hex, "bg")
            end

            -- rgb(r, g, b) / rgba(r, g, b, a)
            local rgb_group = function(_, match)
                local r, g, b = match:match("rgba?%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
                if not r then return end
                local hex = string.format("#%02x%02x%02x", tonumber(r), tonumber(g), tonumber(b))
                return MiniHipatterns.compute_hex_color_group(hex, "bg")
            end

            -- hsl(h, s%, l%) / hsla(...)
            local function hue_to_rgb(p, q, t)
                if t < 0 then t = t + 1 end
                if t > 1 then t = t - 1 end
                if t < 1 / 6 then return p + (q - p) * 6 * t end
                if t < 1 / 2 then return q end
                if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
                return p
            end
            local hsl_group = function(_, match)
                local h, s, l = match:match("hsla?%(%s*(%d+)%s*,%s*(%d+)%%?%s*,%s*(%d+)%%?")
                if not h then return end
                h, s, l = tonumber(h) / 360, tonumber(s) / 100, tonumber(l) / 100
                local r, g, b
                if s == 0 then
                    r, g, b = l, l, l
                else
                    local q = l < 0.5 and l * (1 + s) or l + s - l * s
                    local p = 2 * l - q
                    r = hue_to_rgb(p, q, h + 1 / 3)
                    g = hue_to_rgb(p, q, h)
                    b = hue_to_rgb(p, q, h - 1 / 3)
                end
                local hex = string.format("#%02x%02x%02x", r * 255, g * 255, b * 255)
                return MiniHipatterns.compute_hex_color_group(hex, "bg")
            end

            hipatterns.setup({
                highlighters = {
                    hex_color = hex_color,
                    short_hex = {
                        pattern = "#%x%x%x%f[^%x%w]",
                        group = short_hex_group,
                    },
                    rgb_color = {
                        pattern = "rgba?%(%d+,?%s*%d+,?%s*%d+.-%)",
                        group = rgb_group,
                    },
                    hsl_color = {
                        pattern = "hsla?%(%d+,?%s*%d+%%?,?%s*%d+%%?.-%)",
                        group = hsl_group,
                    },
                },
            })
        end,
    },

    -- Status line
    {
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
    },

    -- Surround
    {
        "nvim-mini/mini.surround",
        event = "VeryLazy",
        config = function()
            require("mini.surround").setup({
                mappings = {
                    add = "ys",
                    delete = "ds",
                    replace = "cs",
                    find = "",
                    find_left = "",
                    highlight = "",
                    update_n_lines = "",
                    suffix_last = "",
                    suffix_next = "",
                },
                search_method = "cover_or_next",
            })

            -- visual mode: mini.surround maps 'ys' there too by default, which
            -- collides with the normal-mode meaning; tpope used 'S' for this
            vim.keymap.del("x", "ys")
            vim.keymap.set("x", "S", [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true })

            -- tpope's "yss" = act on the whole line, ignoring leading whitespace
            vim.keymap.set("n", "yss", "ys_", { remap = true })
        end,
    },
}

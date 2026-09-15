-- nvim/lua/plugins/mini-hipatterns.lua


return {
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
}

-- nvim/lua/plugins/autopairs.lua


return {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
        check_ts = true,
    },
    config = function(_, opts)
        local autopairs = require("nvim-autopairs")
        autopairs.setup(opts)

        local Rule = require("nvim-autopairs.rule")

        local function include_or_generic(o)
            local before = o.line:sub(1, o.col - 1)
            -- #include <...>
            if before:match("^%s*#include%s*$") then
                return true
            end
            -- template/generic: preceded by an identifier, ::, or .
            -- e.g. vector<, std::vector<, Array<, Promise
            if before:match("[%w_][%w_:%.]*$") then
                return true
            end
            return false
        end

        autopairs.add_rules({
            Rule("<", ">", { "c", "cpp", "javascript", "typescript", "javascriptreact", "typescriptreact", "qml" })
                :with_pair(include_or_generic)
                :with_move(function(o)
                    return o.char == ">"
                end),
        })
    end,
}

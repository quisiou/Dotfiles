-- nvim/lua/plugins/neotab.lua


return {
    "kawre/neotab.nvim",
    event = "InsertEnter",
    opts = {
        tabkey = "<Tab>",
        reverse_key = "<S-Tab>",
        act_as_tab = true,   -- normal indent when there's nothing to tab out of
        behavior = "nested", -- prefer the innermost valid pair
        pairs = {
            { open = "(", close = ")" },
            { open = "[", close = "]" },
            { open = "{", close = "}" },
            { open = "'", close = "'" },
            { open = '"', close = '"' },
            { open = "`", close = "`" },
        },
        exclude = {},
    },
}

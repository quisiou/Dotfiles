-- nvim/lua/plugins/blink-cmp.lua


return {
    "saghen/blink.cmp",
    dependencies = { "rafamadriz/friendly-snippets" },
    version = "1.*",
    opts = {
        keymap = {
            preset = "default",
            ["<C-j>"] = { "select_next", "fallback" },
            ["<C-k>"] = { "select_prev", "fallback" },
            ["<S-Tab>"] = { "cancel", "fallback" },
            ["<Tab>"] = { "select_and_accept", "fallback" },
        },
        appearance = { nerd_font_variant = "mono" },
        completion = { documentation = { auto_show = true } },
        sources = { default = { "lsp", "path", "snippets", "buffer" } },
    },
}

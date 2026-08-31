-- nvim/lua/plugins/blink-cmp.lua


return {
    "saghen/blink.cmp",
    dependencies = { "rafamadriz/friendly-snippets" },
    version = "1.*",
    opts = {
        keymap = { preset = "default" },  -- <C-space> trigger, <Tab>/<S-Tab> to cycle
        appearance = { nerd_font_variant = "mono" },
        completion = { documentation = { auto_show = true } },
        sources = { default = { "lsp", "path", "snippets", "buffer" } },
    },
}

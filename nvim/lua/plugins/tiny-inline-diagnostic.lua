-- nvim/lua/plugins/tiny-inline-diagnostic.lua


return {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    opts = {
        options = {
            multilines = {
                enabled = true,
            },
            virt_texts = {
                priority = 2048, -- higher than gitsigns' default, so diagnostics render on top
            },
        }
    },
}

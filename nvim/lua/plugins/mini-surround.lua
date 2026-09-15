-- nvim/lua/plugins/mini-surround.lua


return {
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
}

-- nvim/lua/plugins/marks.lua


return {
    "chentoast/marks.nvim",
    event = "VeryLazy",
    opts = {
        default_mappings = false,
        signs = true,
        mappings = {},
    },
    config = function(_, opts)
        require("marks").setup(opts)

        local set = vim.keymap.set

        set("n", "<leader>Ml", "<cmd>MarksListBuf<CR>", { desc = "List marks in buffer" })
        set("n", "<leader>Mn", function() require("marks").next() end, { desc = "Next mark" })
        set("n", "<leader>MN", function() require("marks").prev() end, { desc = "Prev mark" })

        set("n", "<leader>Md", function() require("marks").delete() end, { desc = "Delete mark by letter" })
        set("n", "<leader>MD", function() require("marks").delete_buf() end, { desc = "Delete all marks in buffer" })

        set("n", "<leader>Mv", function() require("marks").preview() end, { desc = "Preview mark" })
    end,
}

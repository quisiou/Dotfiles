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

        set("n", "<leader>ml", "<cmd>MarksListBuf<CR>", { desc = "List marks in buffer" })
        set("n", "<leader>mn", function() require("marks").next() end, { desc = "Next mark" })
        set("n", "<leader>mp", function() require("marks").prev() end, { desc = "Prev mark" })

        set("n", "<leader>md", function() require("marks").delete() end, { desc = "Delete mark under cursor" })
        set("n", "<leader>mD", function() require("marks").delete_buf() end, { desc = "Delete all marks in buffer" })

        set("n", "<leader>mv", function() require("marks").preview() end, { desc = "Preview mark" })
    end,
}

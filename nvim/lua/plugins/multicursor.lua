-- nvim/lua/plugins/multicursor.lua

return {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    config = function()
        local mc = require("multicursor-nvim")
        mc.setup()

        local set = vim.keymap.set

        -- Add cursor above/below current cursor's column, one line at a time
        set({ "n", "v" }, "<A-k>", function() mc.lineAddCursor(-1) end, { desc = "Add cursor above" })
        set({ "n", "v" }, "<A-j>", function() mc.lineAddCursor(1) end, { desc = "Add cursor below" })

        -- Add/skip cursor by matching word under cursor
        set({ "n", "v" }, "md", function() mc.matchAddCursor(1) end, { desc = "Add cursor on next match" })
        set({ "n", "v" }, "mD", function() mc.matchSkipCursor(1) end, { desc = "Skip to next match" })

        -- Add all matches of word under cursor at once
        set({ "n", "v" }, "mA", function() mc.matchAllAddCursors() end, { desc = "Add cursor on all matches" })

        -- Split visual selection into one cursor per line
        set("v", "ms", mc.splitCursors, { desc = "Split selection into cursors" })

        -- Align cursor columns
        set("v", "ma", mc.alignCursors, { desc = "Align cursors" })

        -- Match new cursors within visual selection by regex
        set("v", "mm", mc.matchCursors, { desc = "Match cursors by regex in selection" })

        -- Clear cursors, falling back to your original Esc behavior
        set("n", "<Esc>", function()
            if not mc.cursorsEnabled() then
                mc.enableCursors()
            elseif mc.hasCursors() then
                mc.clearCursors()
            else
                vim.cmd("nohlsearch")
            end
        end, { desc = "Clear search highlight / multicursor" })

        -- Highlights
        vim.api.nvim_set_hl(0, "MultiCursorCursor", { link = "Cursor" })
        vim.api.nvim_set_hl(0, "MultiCursorVisual", { link = "Visual" })
        vim.api.nvim_set_hl(0, "MultiCursorSign", { link = "SignColumn" })
        vim.api.nvim_set_hl(0, "MultiCursorMatchPreview", { link = "Search" })
        vim.api.nvim_set_hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
        vim.api.nvim_set_hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
        vim.api.nvim_set_hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
    end,
}

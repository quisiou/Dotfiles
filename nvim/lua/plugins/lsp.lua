-- nvim/lua/plugins/lsp.lua


return {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = { "saghen/blink.cmp" },
    config = function()
        local capabilities = require("blink.cmp").get_lsp_capabilities()
        vim.lsp.config("*", { capabilities = capabilities })

        vim.lsp.config("qmlls", {
            cmd = { "qmlls", "-E" },
        })

        vim.lsp.enable({
            "lua_ls",
            "vimls",
            "nixd",
            "marksman",
            "bashls",
            "basedpyright",
            "ruff",
            "clangd",
            "qmlls",
        })

        -- lua_ls needs to know about the `vim` global
        vim.lsp.config("lua_ls", { settings = { Lua = { diagnostics = { globals = { "vim" } } } } })

        -- LSP diagnostics
        vim.diagnostic.config({
            virtual_text = { current_line = true },  -- inline message on the line your cursor is on
            severity_sort = true,
            float = { border = "rounded", source = true },
        })
    end,
}

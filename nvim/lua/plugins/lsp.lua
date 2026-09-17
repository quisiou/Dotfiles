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

        vim.lsp.config("clangd", {
            cmd = {
                "clangd",
                "--query-driver=/usr/bin/gcc,/usr/bin/cc,/usr/bin/*gcc*", -- let clangd ask gcc for its system/kernel include paths
                "--header-insertion=never",   -- kernel code doesn't play well with clangd's IWYU-style auto-includes
                "--background-index",
            },
            root_dir = function(fname)
                local util = require("lspconfig.util")
                return util.root_pattern("compile_commands.json", ".clangd", ".git")(fname)
            end,
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
            virtual_text = false,  -- inline message on current line handled by tiny-inline-diagnostic
            severity_sort = true,
            float = { border = "rounded", source = true },
        })
    end,
}

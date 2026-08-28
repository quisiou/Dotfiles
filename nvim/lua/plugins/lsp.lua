-- nvim/lua/plugins/lsp.lua


return {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
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
        vim.lsp.config("lua_ls", {
            settings = {
                Lua = {
                    diagnostics = { globals = { "vim" } },
                },
            },
        })
    end,
}


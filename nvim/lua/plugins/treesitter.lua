-- nvim/lua/plugins/treesitter.lua


return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        local parsers = {
            "lua",
            "vim",
            "vimdoc",
            "bash",
            "nix",
            "markdown",
            "markdown_inline",
            "qmljs",
            "qmldir",
            "c",
            "cpp",
            "python",
        }

        require("nvim-treesitter").install(parsers):wait(300000)

        -- Derive real filetypes from parser/language names, since they
        -- don't always match (e.g. vimdoc -> help, bash -> sh, and
        -- markdown_inline has no filetype of its own, it's injection-only).
        local filetypes = {}
        for _, lang in ipairs(parsers) do
            for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
                table.insert(filetypes, ft)
            end
        end

        -- Highlighting
        vim.api.nvim_create_autocmd("FileType", {
            pattern = filetypes,
            callback = function()
                vim.treesitter.start()
            end,
        })

        -- Indentation (experimental, provided by the plugin)
        vim.api.nvim_create_autocmd("FileType", {
            pattern = filetypes,
            callback = function()
                vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end,
        })
    end,
}


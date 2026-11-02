-- nvim/lua/plugins/vimtex.lua


return {
    "lervag/vimtex",
    lazy = false,
    init = function()
        vim.g.vimtex_mappings_prefix = "<localleader>L"
        vim.g.vimtex_view_method = "zathura"
        vim.g.vimtex_compiler_method = "latexmk"
        vim.g.vimtex_compiler_latexmk_engines = { _ = "-lualatex" }
        vim.g.vimtex_compiler_latexmk = {
            options = {
                "-interaction=nonstopmode",
                "-halt-on-error",
                "-synctex=1",
            },
        }
        vim.g.vimtex_quickfix_mode = 0 -- don't open quickfix on every warning
        vim.g.vimtex_syntax_conceal_disable = 1
    end,
}

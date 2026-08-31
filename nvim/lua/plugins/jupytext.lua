-- nvim/lua/plugins/jupytext.lua


return {
    "GCBallesteros/jupytext.nvim",
    lazy = false,
    config = function()
        require("jupytext").setup({
            custom_language_formatting = {
                python = {
                extension = "md",
                style = "markdown",
                force_ft = "markdown",
                },
            },
        })
    end,
}

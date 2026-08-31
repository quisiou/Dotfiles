-- nvim/lua/plugins/render-markdown.lua


return {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" }, -- safe to lazy-load on filetype here, jupytext sets this itself via force_ft
    dependencies = { "nvim-treesitter/nvim-treesitter" }, -- you already have this installed
    opts = {
        code = {
            style = "full",       -- adds background + border around code blocks, closest to "cell" look
            border = "thin",
        },
        heading = {
            enabled = true,
            sign = false,
        },
    },
}

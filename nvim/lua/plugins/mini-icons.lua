-- nvim/lua/plugins/mini-icons.lua


return {
    "nvim-mini/mini.icons",
    lazy = false,   -- must be ready before neo-tree/lualine ask for icons
    priority = 1000, -- load before other non-lazy plugins that consume icons
    config = function()
        require("mini.icons").setup()
        -- makes any plugin that only knows nvim-web-devicons work transparently
        require("mini.icons").mock_nvim_web_devicons()
    end,
}

-- nvim/lua/plugins/highlight-colors.lua


return {
  "brenoprata10/nvim-highlight-colors",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("nvim-highlight-colors").setup({
      ---Render style
      ---@usage 'background'|'foreground'|'virtual'
      render = "virtual",

      ---Set virtual symbol (requires render to be set to 'virtual')
      virtual_symbol = "■",

      ---Position of the virtual symbol relative to the color code
      ---@usage 'inline'|'eol'|'eow'
      virtual_symbol_position = "inline",

      ---Highlight named colors, e.g. 'green'
      enable_named_colors = true,

      ---Highlight tailwind colors, e.g. 'bg-blue-500'
      enable_tailwind = false,

      -- Which formats to detect
      enable_hex = true,
      enable_short_hex = true,
      enable_rgb = true,
      enable_hsl = true,
      enable_var_usage = true, -- CSS var() referencing a color
      enable_ansi = true,

      ---Exclude filetypes or buftypes from highlighting
      exclude_filetypes = {},
      exclude_buftypes = {},
    })
  end,
}

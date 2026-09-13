-- nvim/lua/plugins/goto-preview.lua


return {
    'rmagatti/goto-preview',
    dependencies = { 'rmagatti/logger.nvim' },
    event = 'LspAttach',
    opts = {
        same_file_float_preview = false,
        default_mappings = false,
        width = 120,
        height = 25,
        border = { '↖', '─', '↗', '│', '↘', '─', '↙', '│' },
        focus_on_open = true,
        dismiss_on_move = false,
    },
}

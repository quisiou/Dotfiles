-- nvim/lua/plugins/octo.lua


return {
    'pwntester/octo.nvim',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope.nvim',
    },
    cmd = 'Octo',
    keys = {
        { '<leader>gi', '<cmd>Octo issue list<cr>', desc = 'Octo: issue list' },
        { '<leader>gp', '<cmd>Octo pr list<cr>', desc = 'Octo: pr list' },
    },
    opts = {
        default_to_projects_v2 = true,
        picker = 'telescope',
        issues = {
            order_by = {
                field = 'CREATED_AT',
                direction = 'DESC',
            },
        },
    },
}

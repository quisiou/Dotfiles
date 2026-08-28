-- nvim/lua/plugins/neo-tree.lua


return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
    },
    keys = {
        { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Neo-tree sidebar" },
    },
    init = function()
        vim.api.nvim_create_autocmd("BufEnter", {
            group = vim.api.nvim_create_augroup("load_neo_tree", { clear = true }),
            desc = "Load neo-tree eagerly when opening a directory, so it can hijack netrw",
            callback = function(args)
                local stat = vim.uv.fs_stat(args.file)
                if not stat or stat.type ~= "directory" then
                    return
                end
                require("neo-tree")
                return true -- run once
            end,
        })
    end,
    opts = {
        close_if_last_window = true,
        popup_border_style = "rounded",
        filesystem = {
            bind_to_cwd = false,
            filtered_items = {
                visible = true,
                hide_dotfiles = false,
                hide_gitignored = false,
            },
            follow_current_file = {
                enabled = true,
            },
        },
        default_component_configs = {
            indent = {
                with_expanders = true,
                expander_collapsed = "",
                expander_expanded = "",
            },
            icon = {
                folder_closed = "",
                folder_open = "",
                folder_empty = "󰜌",
            },
        },
        window = {
            width = 30,
            mappings = {
                ["<space>"] = "none",
                ["l"] = "open",
                ["h"] = "close_node",
                ["<bs>"] = "navigate_up",
                ["O"] = {
                    function(state)
                        local node = state.tree:get_node()
                        if node.type ~= "directory" then
                            vim.notify("Not a directory", vim.log.levels.WARN)
                            return
                        end
                        vim.cmd("Open " .. vim.fn.fnameescape(node.path))
                    end,
                    desc = "open_as_workspace",
                },
            },
        },
    },
}

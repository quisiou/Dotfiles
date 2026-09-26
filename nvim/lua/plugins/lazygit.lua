-- nvim/lua/plugins/lazygit.lua


local function open_floating_terminal(cmd)
    local width = math.floor(vim.o.columns * 0.9)
    local height = math.floor(vim.o.lines * 0.9)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local buf = vim.api.nvim_create_buf(false, true)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
    })

    vim.fn.termopen(cmd, {
        on_exit = function()
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end
        end,
    })

    vim.cmd("startinsert")
end

return {
    "kdheepak/lazygit.nvim",
    cmd = "LazyGit",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
        {
            "<leader>gd",
            function()
                open_floating_terminal("cd " .. vim.fn.expand("~") .. " && gh-dash")
            end,
            desc = "Open gh-dash",
        },
        {
            "<leader>gb",
            function()
                vim.fn.jobstart({ "gh", "repo", "view", "--json", "owner", "-q", ".owner.login" }, {
                    stdout_buffered = true,
                    on_stdout = function(_, data)
                        local owner = data and data[1]
                        if not owner or owner == "" then
                            open_floating_terminal("gh board")
                            return
                        end

                        local query = [[
                            query($login: String!) {
                                repositoryOwner(login: $login) {
                                    ... on ProjectV2Owner {
                                        projectsV2(first: 20) {
                                            nodes {
                                                number
                                                title
                                                items(first: 1, query: "assignee:@me") {
                                                    totalCount
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        ]]

                        vim.fn.jobstart({
                            "gh", "api", "graphql",
                            "-f", "query=" .. query,
                            "-f", "login=" .. owner,
                            "--jq", ".data.repositoryOwner.projectsV2.nodes[]? | select(.items.totalCount > 0) | \"\\(.number)\\t\\(.title)\"",
                        }, {
                            stdout_buffered = true,
                            on_stdout = function(_, lines)
                                lines = vim.tbl_filter(function(l) return l ~= "" end, lines or {})

                                -- keep only lines that actually match "<number>\t<title>" — drop anything malformed
                                local parsed = {}
                                for _, line in ipairs(lines) do
                                    local number, title = line:match("^(%d+)\t(.*)$")
                                    if number then
                                        table.insert(parsed, { number = number, title = title })
                                    end
                                end

                                if #parsed == 0 then
                                    vim.notify("No projects with items assigned to you under " .. owner, vim.log.levels.WARN)
                                    open_floating_terminal("gh board --owner " .. owner)
                                elseif #parsed == 1 then
                                    open_floating_terminal("gh board " .. parsed[1].number .. " --owner " .. owner)
                                else
                                    local choices, numbers = {}, {}
                                    for _, p in ipairs(parsed) do
                                        local label = p.number .. " — " .. p.title
                                        table.insert(choices, label)
                                        numbers[label] = p.number
                                    end
                                    vim.ui.select(choices, { prompt = "Select a project" }, function(choice)
                                        if choice then
                                            open_floating_terminal("gh board " .. numbers[choice] .. " --owner " .. owner)
                                        end
                                    end)
                                end
                            end,
                            on_stderr = function() end,
                        })
                    end,
                    on_stderr = function() end,
                })
            end,
            desc = "Open project board with gh-board",
        },
    },
}

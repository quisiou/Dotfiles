-- nvim/lua/plugins/lsp.lua

-------------------------------------------------------------------------------
-- Diagnostics: filter noisy rules, demote "just extra code" to dimmed hints
-------------------------------------------------------------------------------

-- Rules hidden entirely. Filtered in Neovim, so this works even when a
-- project's own basedpyright config overrides the editor settings.
local SUPPRESSED_RULES = {
    -- Any / Unknown
    "reportAny",
    "reportUnknownParameterType",
    "reportUnknownArgumentType",
    "reportUnknownVariableType",
    "reportUnknownMemberType",
    "reportUnknownLambdaType",
    "reportMissingParameterType",
    -- untyped libs
    "reportMissingTypeStubs",
    "reportUntypedFunctionDecorator",
    "reportUntypedClassDecorator",
    "reportUntypedBaseClass",
    "reportUntypedNamedTuple",
    -- class design
    "reportImplicitOverride",
    "reportUnannotatedClassAttribute",
    "reportUninitializedInstanceVariable",
    "reportMissingSuperCall",
    "reportImplicitAbstractClass",
    "reportUnsafeMultipleInheritance",
    -- style
    "reportUnusedCallResult",
    "reportImplicitStringConcatenation",
    "reportCallInDefaultInitializer",
    "reportPrivateUsage",
    "reportPrivateLocalImportUsage",
    "reportImportCycles",
    "reportDuplicateImport", -- ruff covers this
}

-- Built from the list above: a lookup set for the handler, and "none"
-- overrides for the server (still useful in projects without their own config).
local SUPPRESSED = {}
local SEVERITY_OVERRIDES = {}
for _, rule in ipairs(SUPPRESSED_RULES) do
    SUPPRESSED[rule] = true
    SEVERITY_OVERRIDES[rule] = "none"
end

-- Codes forced to Hint severity regardless of what the server sends.
local DEMOTED_CODES = {
    -- basedpyright
    reportUnusedImport = true,
    reportUnusedVariable = true,
    reportUnusedParameter = true,
    reportUnusedClass = true,
    reportUnusedFunction = true,
    -- ruff
    F401 = true,
    F841 = true,
    ARG001 = true, ARG002 = true, ARG003 = true, ARG004 = true, ARG005 = true,
}

local HINT = vim.lsp.protocol.DiagnosticSeverity.Hint
local UNNECESSARY = vim.lsp.protocol.DiagnosticTag.Unnecessary

-- Drop suppressed diagnostics; make demoted ones hints tagged so Neovim greys
-- the code out. Returns the filtered list.
local function process_diagnostics(items)
    local kept = {}
    for _, d in ipairs(items or {}) do
        if not SUPPRESSED[d.code] then
            if DEMOTED_CODES[d.code] then
                d.severity = HINT
                d.tags = d.tags or {}
                if not vim.tbl_contains(d.tags, UNNECESSARY) then
                    table.insert(d.tags, UNNECESSARY)
                end
            end
            table.insert(kept, d)
        end
    end
    return kept
end

local filtering_handlers = {
    -- push diagnostics
    ["textDocument/publishDiagnostics"] = function(err, result, ctx)
        if result then
            result.diagnostics = process_diagnostics(result.diagnostics)
        end
        return vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
    end,
    -- pull diagnostics
    ["textDocument/diagnostic"] = function(err, result, ctx)
        if result and result.items then
            result.items = process_diagnostics(result.items)
        end
        return vim.lsp.diagnostic.on_diagnostic(err, result, ctx)
    end,
}

-------------------------------------------------------------------------------
-- Server configs
-------------------------------------------------------------------------------

local servers = {
    lua_ls = {
        -- needs to know about the `vim` global
        settings = { Lua = { diagnostics = { globals = { "vim" } } } },
    },

    qmlls = {
        cmd = { "qmlls", "-E" },
    },

    clangd = {
        cmd = {
            "clangd",
            "--query-driver=/usr/bin/gcc,/usr/bin/cc,/usr/bin/*gcc*", -- let clangd ask gcc for its system/kernel include paths
            "--header-insertion=never",   -- kernel code doesn't play well with clangd's IWYU-style auto-includes
            "--background-index",
        },
        root_dir = function(fname)
            local util = require("lspconfig.util")
            return util.root_pattern("compile_commands.json", ".clangd", ".git")(fname)
        end,
    },

    texlab = {
        settings = {
            texlab = {
                build = {
                    auxDirectory = "build",
                    logDirectory = "build",
                },
            },
        },
    },

    basedpyright = {
        handlers = filtering_handlers,
        settings = {
            basedpyright = {
                disableOrganizeImports = true,
                analysis = {
                    typeCheckingMode = "recommended",
                    diagnosticSeverityOverrides = SEVERITY_OVERRIDES,
                },
            },
        },
    },

    ruff = {
        handlers = filtering_handlers,
    },
}

-- Servers to start. Those without an entry in `servers` use their defaults.
local enabled_servers = {
    "lua_ls", "vimls", "nixd", "marksman", "bashls",
    "basedpyright", "ruff",
    "clangd", "qmlls", "texlab",
}

-------------------------------------------------------------------------------
-- Setup functions
-------------------------------------------------------------------------------

local function setup_servers()
    local capabilities = require("blink.cmp").get_lsp_capabilities()
    vim.lsp.config("*", { capabilities = capabilities })

    for name, config in pairs(servers) do
        vim.lsp.config(name, config)
    end

    vim.lsp.enable(enabled_servers)
end

local function setup_diagnostics()
    vim.diagnostic.config({
        virtual_text = false, -- inline message on current line handled by tiny-inline-diagnostic
        severity_sort = true,
        float = { border = "rounded", source = true },
    })
end

-- Greyed-out + hint-colored undercurl for code tagged "unnecessary"
local function setup_highlights()
    local function apply()
        local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
        local hint = vim.api.nvim_get_hl(0, { name = "DiagnosticHint", link = false })
        vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", {
            fg = comment.fg,
            undercurl = true,
            sp = hint.fg,
        })
    end

    apply()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = apply })
end

local function setup_keymaps()
    local map = vim.keymap.set

    -- Code actions
    local function source_action(kind)
        return function()
            vim.lsp.buf.code_action({
                context = { only = { kind }, diagnostics = {} },
                apply = true,
            })
        end
    end

    map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
    map("n", "<leader>ci", source_action("source.organizeImports"), { desc = "Organize imports" })
    map("n", "<leader>cf", source_action("source.fixAll"), { desc = "Fix all" })
    map("n", "<leader>cq", source_action("quickfix"), { desc = "Quickfix" })

    -- Per-file diagnostic lists by severity
    local function diag_list(severity, name)
        return function()
            if #vim.diagnostic.get(0, { severity = severity }) == 0 then
                vim.notify("No " .. name .. " in this file", vim.log.levels.INFO)
                return
            end
            vim.diagnostic.setloclist({ severity = severity, open = true, title = name })
        end
    end

    map("n", "<leader>ce", diag_list(vim.diagnostic.severity.ERROR, "Errors"), { desc = "List errors" })
    map("n", "<leader>cw", diag_list(vim.diagnostic.severity.WARN, "Warnings"), { desc = "List warnings" })
    map("n", "<leader>ch", diag_list(vim.diagnostic.severity.HINT, "Hints"), { desc = "List hints" })

    -- Close list/quickfix windows with q
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "qf",
        callback = function(ev)
            map("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
        end,
    })
end

-------------------------------------------------------------------------------
-- Plugin spec
-------------------------------------------------------------------------------

return {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = { "saghen/blink.cmp" },
    config = function()
        setup_servers()
        setup_diagnostics()
        setup_highlights()
        setup_keymaps()
    end,
}

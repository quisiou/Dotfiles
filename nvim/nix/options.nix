# nvim/nix/options.nix


{ lib, pkgs }:

{
    package = lib.mkOption {
        description = "The neovim package to use.";
        type = lib.types.package;
        default = pkgs.neovim;
    };

    extraKeymaps = lib.mkOption {
        description = "Extra settings to append to `lua/keymaps.lua`";
        type = lib.types.lines;
        default = "";
    };
    extraOptions = lib.mkOption {
        description = "Extra settings to append to `lua/options.lua`";
        type = lib.types.lines;
        default = "";
    };
    extraPlugins = lib.mkOption {
        description = ''
            Extra plugin specs. Each attribute name is a file name (without `.lua`)
            written to `lua/plugins/`, and its value is the Lua content of that file.
            Each file must return a lazy.nvim spec table.
        '';
        type = lib.types.attrsOf lib.types.lines;
        default = { };
        example = lib.literalExpression ''
            {
                telescope = '''
                    return {
                        "nvim-telescope/telescope.nvim",
                        dependencies = { "nvim-lua/plenary.nvim" },
                    }
                ''';
            }
        '';
    };
}

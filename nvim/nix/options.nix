# nvim/nix/options.nix


{ lib, pkgs }:

{
    package = lib.mkOption {
        description = "The neovim package to use.";
        type = lib.types.package;
        default = pkgs.neovim;
    };
    extraKeymaps = lib.mkOption {
        description = "Written to `lua/user/keymaps.lua`, which `keymaps.lua` loads at its end";
        type = lib.types.lines;
        default = "";
    };
    extraOptions = lib.mkOption {
        description = "Written to `lua/user/options.lua`, which `options.lua` loads at its end";
        type = lib.types.lines;
        default = "";
    };
    extraPackages = lib.mkOption {
        description = ''
            Packages added to neovim's PATH only (appended, so your own tools take priority),
            for CLIs that plugins call, e.g. `jupytext`. They are not added to your global PATH.
        '';
        type = lib.types.listOf lib.types.package;
        default = [ ];
        example = lib.literalExpression "[ pkgs.ripgrep ]";
    };
    extraPlugins = lib.mkOption {
        description = ''
            Extra plugin specs. Each attribute name is a file name (without `.lua`)
            written to `lua/plugins/`, and its value is the Lua content of that file.
            Each file must return a lazy.nvim spec table. The name must not match a file
            in the repo's `lua/plugins/`; to change an existing plugin, use a different
            name with the same plugin, as lazy merges specs for the same plugin.
        '';
        type = lib.types.attrsOf lib.types.lines;
        default = { };
        example = lib.literalExpression ''
            {
                telescope-tweaks = '''
                    return {
                        "nvim-telescope/telescope.nvim",
                        opts = { defaults = { layout_strategy = "vertical" } },
                    }
                ''';
            }
        '';
    };
    lockfile = lib.mkOption {
        description = ''
            Path to a writable `lazy-lock.json`, typically the one in your Dotfiles checkout.
            It is linked outside the store so lazy.nvim can update it. When null, the lockfile
            from the flake source is used; that one is read-only, so plugin updates from
            inside nvim will fail.
        '';
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/home/user/Dotfiles/nvim/lazy-lock.json";
    };
}

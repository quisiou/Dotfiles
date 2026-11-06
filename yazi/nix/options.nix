# yazi/nix/options.nix


{ lib, pkgs }:

{
    package = lib.mkOption {
        description = "The yazi package to use.";
        type = lib.types.package;
        default = pkgs.yazi.override { _7zz = pkgs._7zz-rar; };
    };
    extraKeymaps = lib.mkOption {
        description = ''
            Extra settings merged into `keymap.toml`.
            They are placed before the defaults, so `prepend_keymap` entries here take priority.
        '';
        type = lib.types.lines;
        default = "";
    };
    extraOptions = lib.mkOption {
        description = ''
            Extra settings merged into `yazi.toml`.
            They are placed before the defaults, so `prepend_rules` entries here take priority
            (the defaults end with a catch-all rule).
        '';
        type = lib.types.lines;
        default = "";
    };
    extraPlugins = lib.mkOption {
        description = ''
            Extra yazi plugins. Each attribute name is the plugin name (without `.yazi`).
            Set exactly one of:
            - `src`: a source tree, typically a non-flake flake input, linked as
            `plugins/<name>.yazi`. Use `subdir` when the plugin is inside a monorepo.
            - `text`: Lua written to `plugins/<name>.yazi/main.lua`.
            The name must not match a plugin in the repo's `plugins/`.
        '';
        type = lib.types.attrsOf (lib.types.submodule {
            options = {
                src = lib.mkOption {
                    description = "Source tree of the plugin, e.g. a `flake = false` flake input.";
                    type = lib.types.nullOr lib.types.path;
                    default = null;
                    example = lib.literalExpression "inputs.yazi-plugins";
                };
                subdir = lib.mkOption {
                    description = ''
                        Directory inside `src` that holds the plugin (with its `main.lua`).
                        For monorepos like yazi-rs/plugins; null when `src` itself is the plugin.
                    '';
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    example = "smart-enter.yazi";
                };
                text = lib.mkOption {
                    description = "Lua content of the plugin's `main.lua`.";
                    type = lib.types.lines;
                    default = "";
                };
            };
        });
        default = { };
    };
}

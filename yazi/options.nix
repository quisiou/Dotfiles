# yazi/options.nix


{ lib, pkgs }:

{
    package = lib.mkOption {
        description = "The yazi package to use.";
        type = lib.types.package;
        default = pkgs.yazi;
    };

    extraKeymaps = lib.mkOption {
        description = "Extra settings to append to `keymap.toml`";
        type = lib.types.lines;
        default = "";
    };
    extraOptions = lib.mkOption {
        description = "Extra settings to append to `yazi.toml`";
        type = lib.types.lines;
        default = "";
    };
}

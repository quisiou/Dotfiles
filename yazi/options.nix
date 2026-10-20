# yazi/options.nix


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
}

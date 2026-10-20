# hypr/nix/options.nix


{ lib }:

{
    package = lib.mkOption {
        description = ''
            Hyprland package to install into the user profile. Leave null when the system
            already provides it (NixOS `programs.hyprland`), and set it to that same package
            otherwise: a different build would put a mismatched `hyprctl` first in PATH.
        '';
        type = lib.types.nullOr lib.types.package;
        default = null;
        example = lib.literalExpression "pkgs.hyprland";
    };

    extraAutostart = lib.mkOption {
        description = "Extra settings to append to `autostart` config";
        type = lib.types.lines;
        default = "";
    };
    extraConfig = lib.mkOption {
        description = ''
            Settings written to `user/init.lua`, run after the theme loads and after
            `plugins` are loaded, but before any default or user config file.
        '';
        type = lib.types.lines;
        default = "";
    };
    extraEnv = lib.mkOption {
        description = "Extra settings to append to `env` config";
        type = lib.types.lines;
        default = "";
    };
    extraInput = lib.mkOption {
        description = "Extra settings to append to `input` config";
        type = lib.types.lines;
        default = "";
    };
    extraKeybinds = lib.mkOption {
        description = "Extra settings to append to `keybinds` config";
        type = lib.types.lines;
        default = "";
    };
    extraLookAndFeel = lib.mkOption {
        description = "Extra settings to append to `look and feel` config";
        type = lib.types.lines;
        default = "";
    };
    extraMonitors = lib.mkOption {
        description = "Extra settings to append to `monitors` config";
        type = lib.types.lines;
        default = "";
    };
    extraVariables = lib.mkOption {
        description = "Extra settings to append to `variables` config";
        type = lib.types.lines;
        default = "";
    };
    extraWindowRules = lib.mkOption {
        description = "Extra settings to append to `window rules` config";
        type = lib.types.lines;
        default = "";
    };
    plugins = lib.mkOption {
        description = ''
            Plugins to load at startup. A package is loaded from `lib/lib<pname>.so`,
            a path is used as is. They must be compatible with the running Hyprland's version.
        '';
        type = lib.types.listOf (lib.types.either lib.types.package lib.types.path);
        default = [ ];
    };
}

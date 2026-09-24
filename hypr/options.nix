# hypr/options.nix


{ lib, pkgs }:

{
    package = lib.mkOption {
        description = "The hyprland package to use.";
        type = lib.types.package;
        default = pkgs.hyprland;
    };

    extraAutostart = lib.mkOption {
        description = "Extra settings to append to `autostart` config";
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
}

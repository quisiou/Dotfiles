# btop/options.nix


{ lib, pkgs, config }:

{
    package = lib.mkOption {
        description = "The btop package to use.";
        type = lib.types.package;
        default = pkgs.btop;
    };

    settings = lib.mkOption {
        description = ''
            Btop internal settings (check `btop --help` for more information).
            These can be changed later using the provided script or by manually editing the files.
        '';
        type = lib.types.submodule {
            options = {
                configPath = lib.mkOption {
                    description = "Path to the config file to be used.";
                    type = lib.types.str;
                    default = "${config.xdg.configHome}/btop/btop.conf";
                };
                filter = lib.mkOption {
                    description = "Set an initial process filter.";
                    type = lib.types.str;
                    default = "";
                };
                forceUTF = lib.mkOption {
                    description = "Override automatic UTF locale detection.";
                    type = lib.types.bool;
                    default = false;
                };
                lowColor = lib.mkOption {
                    description = "Disable true color, 256 colors only.";
                    type = lib.types.bool;
                    default = false;
                };
                preset = lib.mkOption {
                    description = "Start with a preset (0-9).";
                    type = lib.types.ints.between 0 9;
                    default = 0;
                };
                themesDir = lib.mkOption {
                    description = "Path to a custom themes directory.";
                    type = lib.types.str;
                    default = "${config.xdg.configHome}/btop/themes";
                };
                tty = lib.mkOption {
                    description = "Force tty mode with ANSI graph symbols and 16 colors only.";
                    type = lib.types.bool;
                    default = false;
                };
                update = lib.mkOption {
                    description = "Set an initial update rate in milliseconds.";
                    type = lib.types.ints.positive;
                    default = 100;
                };
            };
        };
        default = { };
    };

}

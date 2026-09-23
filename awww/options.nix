# awww/options.nix


{ lib, pkgs }:

{
    package = lib.mkOption {
        description = "The awww package to use.";
        type = lib.types.package;
        default = pkgs.awww;
    };

    transition = lib.mkOption {
        description = ''
            Wallpaper transition settings (check awww's man page for documentation).
            These can be changed later using the provided script.
        '';
        type = lib.types.submodule {
            options = {
                type = lib.mkOption {
                    description = "Transition style when changing wallpaper.";
                    type = lib.types.enum [
                        "none" "simple" "fade"
                        "left" "right" "top" "bottom" "center"
                        "wipe" "wave" "grow" "outer"
                        "any" "random"
                    ];
                    default = "fade";
                };
                duration = lib.mkOption {
                    description = "Transition duration when changing wallpaper.";
                    type = lib.types.float;
                    default = 1.0;
                };
            };
        };
        default = {};
    };
}

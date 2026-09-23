# awww/options.nix


{ lib, pkgs }:

{
    package = lib.mkOption {
        description = "The awww package to use.";
        type = lib.types.package;
        default = pkgs.awww;
    };

    settings = lib.mkOption {
        description = ''
            Wallpaper image settings (check awww-img man page for documentation).
            These can be changed later using the provided script or by manually editing the files.
        '';
        type = lib.types.submodule {
            options = {
                cropGravity = {
                    description = ''
                        Specify which portion of the image to anchor when cropping.
                        Only used when `resize` is set to `crop`.
                    '';
                    type = lib.types.enum [
                        "top" "right" "bottom" "left" "center"
                        "top-left" "top-right"
                        "bottom-left" "bottom-right"
                    ];
                    default = "center";
                };
                fillColor = {
                    description = "Which color to fill the padding with when not resizing.";
                    type = lib.types.nonEmptyStr;
                    default = "000000";
                };
                filter = {
                    description = "Filter to use when scaling images.";
                    type = lib.types.enum [ "Nearest" "Bilinear" "CatmullRom" "Mitchell" "Lanczos3" ];
                    default = "Lanczos3";
                };
                invertY = {
                    description = "Inverts the y position set in `transition.pos` option.";
                    type = lib.types.bool;
                    default = false;
                };
                outputs = {
                    description = ''
                        Comma separated list of outputs to display the image at.
                        If it isn't set, the image is displayed on all outputs.
                    '';
                    type = lib.types.str;
                    default = "";
                };
                resize = {
                    description = "Whether to resize the image and the method by which to resize it.";
                    type = lib.types.enum [ "no" "crop" "fit" "stretch" ];
                    default = "crop";
                };
                transition = lib.mkOption {
                    description = "Wallpaper transition settings.";
                    type = lib.types.submodule (submoduleArgs: {
                        options = {
                            angle = lib.mkOption {
                                description = ''
                                    This is used for the wipe and wave transitions.
                                    It controls the angle of the wipe.
                                '';
                                type = lib.types.float;
                                default = 45.0;
                            };
                            bezier = lib.mkOption {
                                description = ''
                                    Bezier curve to use for the transition animation.
                                    String format is `f1,f2,f3,f4`, all floats.
                                '';
                                type = lib.types.nonEmptyStr;
                                default = ".54,0,.34,.99";
                            };
                            duration = lib.mkOption {
                                description = "Transition duration when changing wallpaper.";
                                type = lib.types.float;
                                default = 3.0;
                            };
                            fps = lib.mkOption {
                                description = "Frame rate for the transition effect.";
                                type = lib.types.ints.between 0 255;
                                default = 30;
                            };
                            pos = lib.mkOption {
                                description = ''
                                    This is only used for the grow and outer transitions.
                                    It controls the center of circle.
                                        - It can be given as `x,y`:
                                            - Percentage:   `0.5,0.5` (50% width, 50% height)
                                            - Values:       `200,400` (200px from left, 400px from top)
                                        - It can be a preset string: [
                                            `top` `right` `bottom` `left` `center`
                                            `top-left` `top-right`
                                            `bottom-left` `bottom-right`
                                        ]
                                '';
                                type = lib.types.nonEmptyStr;
                                default = "center";
                            };
                            step = lib.mkOption {
                                description = "How fast the transition approaches the new image.";
                                type = lib.types.ints.between 0 255;
                                default = if submoduleArgs.config.type == "simple" then 2 else 90;
                            };
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
                            wave = lib.mkOption {
                                description = ''
                                    Currently only used for wave transition to control the width and height of each wave.
                                    String format is `width,height`, all floats.
                                '';
                                type = lib.types.nonEmptyStr;
                                default = "20,20";
                            };
                        };
                    });
                    default = { };
                };
            };
        };
        default = { };
    };
}

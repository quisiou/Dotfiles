# awww/nix/options.nix


{ lib, pkgs }:

let
    # Every setting here has an environment variable in awww-img(1); null keeps awww's own default
    opt = type: description: lib.mkOption {
        inherit description;
        type = lib.types.nullOr type;
        default = null;
    };
in
{
    package = lib.mkOption {
        description = "The awww package to use.";
        type = lib.types.package;
        default = pkgs.awww;
    };

    settings = lib.mkOption {
        description = ''
            Defaults for `awww img`, set through the environment variables awww reads
            (see awww-img(1)). Flags given on a call still take precedence; null leaves awww's own default.
            The wallpaper picker passes the transition type and duration on every call, so
            those two only affect manual calls and other scripts.
        '';
        default = { };
        type = lib.types.submodule {
            options = {
                invertY = opt lib.types.bool
                    "Invert the y position given in `transition.pos` (AWWW_INVERT_Y).";

                transition = lib.mkOption {
                    description = "Wallpaper transition defaults.";
                    default = { };
                    type = lib.types.submodule {
                        options = {
                            type = opt (lib.types.enum [
                                "none" "simple" "fade" "left" "right" "top" "bottom"
                                "wipe" "wave" "grow" "center" "any" "outer" "random"
                            ]) "Transition style (AWWW_TRANSITION). awww's default is `simple`.";

                            step = opt (lib.types.ints.between 0 255)
                                "How fast the transition approaches the new image, 255 switches instantly (AWWW_TRANSITION_STEP). awww uses 2 for `simple` and 90 otherwise.";

                            duration = opt lib.types.number
                                "Transition length in seconds (AWWW_TRANSITION_DURATION). Not used by `simple`. awww's default is 3.";

                            fps = opt (lib.types.ints.between 0 255)
                                "Frame rate of the transition (AWWW_TRANSITION_FPS). awww's default is 30.";

                            angle = opt lib.types.number
                                "Angle in degrees for the wipe and wave transitions: 0 is right to left, 90 top to bottom, 270 bottom to top (AWWW_TRANSITION_ANGLE). awww's default is 45.";

                            pos = opt lib.types.nonEmptyStr
                                "Center of the grow and outer transitions, as `x,y` (AWWW_TRANSITION_POS). Floats are percentages (`0.5,0.5` is the middle) and integers are pixels from the left and from the bottom. Presets: center, top, left, right, bottom, top-left, top-right, bottom-left, bottom-right.";

                            bezier = opt lib.types.nonEmptyStr
                                "Bezier curve of the animation, `f1,f2,f3,f4` (AWWW_TRANSITION_BEZIER). awww's default is `.54,0,.34,.99`.";

                            wave = opt lib.types.nonEmptyStr
                                "Width and height of each wave for the wave transition, `width,height` (AWWW_TRANSITION_WAVE). awww's default is `20,20`.";
                        };
                    };
                };
            };
        };
    };
}

# btop/nix/options.nix


{ lib, pkgs }:

{
    package = lib.mkOption {
        description = "The btop package to use.";
        type = lib.types.package;
        default = pkgs.btop;
    };

    extraConfig = lib.mkOption {
        description = ''
            Keys of `btop.conf` written literally. Each entry replaces the value of that key in
            the repo's `btop.conf`, which is the base; keys that don't exist there are an error.
            The command line flags map to keys too: `-u` is `update_ms`, `-l` is `truecolor`
            (inverted) and `-t` / `--no-tty` is `force_tty`.
            The result is a read-only file, so changes made in btop's own menu aren't saved;
            consider `save_config_on_exit = false`.
        '';
        type = lib.types.attrsOf (lib.types.oneOf [ lib.types.bool lib.types.int lib.types.float lib.types.str ]);
        default = { };
        example = lib.literalExpression "{ update_ms = 500; truecolor = false; proc_sorting = \"cpu lazy\"; }";
    };

    preset = lib.mkOption {
        description = ''
            Start btop with this preset (0-9) every time, as `btop --preset N`. Presets are the
            ones defined by the `presets` key of btop.conf; 0 shows all boxes with default
            settings. It works by wrapping the binary, so it applies even though btop.conf is
            read-only.
        '';
        type = lib.types.nullOr (lib.types.ints.between 0 9);
        default = null;
    };
}

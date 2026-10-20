# kitty/nix/options.nix


{ lib, pkgs }:

{
    package = lib.mkOption {
        description = "The kitty package to use.";
        type = lib.types.package;
        default = pkgs.kitty;
    };

    extraConfig = lib.mkOption {
        description = ''
            Extra settings written to `user.conf`, which `kitty.conf` includes last,
            so they override the defaults.
        '';
        type = lib.types.lines;
        default = "";
    };
}

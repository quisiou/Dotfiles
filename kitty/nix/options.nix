# kitty/nix/options.nix


{ lib, pkgs }:

{
    package = lib.mkOption {
        description = "The kitty package to use.";
        type = lib.types.package;
        default = pkgs.kitty;
    };

    extraConfig = lib.mkOption {
        description = "Extra settings to append to `kitty.conf`";
        type = lib.types.lines;
        default = "";
    };
}

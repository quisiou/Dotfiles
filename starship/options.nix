# starship/options.nix


{ lib, pkgs }:

{
    package = lib.mkOption {
        description = "The starship package to use.";
        type = lib.types.package;
        default = pkgs.starship;
    };
}

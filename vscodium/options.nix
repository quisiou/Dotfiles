# vscodium/options.nix


{ lib, pkgs }:

{
    package = lib.mkOption {
        description = "The vscodium package to use.";
        type = lib.types.package;
        default = pkgs.vscodium;
    };
}

# fastfetch/options.nix


{ lib, pkgs }:

{
    package = lib.mkOption {
        description = "The fastfetch package to use.";
        type = lib.types.package;
        default = pkgs.fastfetch;
    };
}

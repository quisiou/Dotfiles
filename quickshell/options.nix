# quickshell/options.nix


{ lib, pkgs }:

{
    package = lib.mkOption {
        description = "The quickshell package to use.";
        type = lib.types.package;
        default = pkgs.quickshell;
    };
}

# zsh/nix/options.nix


{ lib, pkgs }:

{
    package = lib.mkOption {
        description = "The zsh package to use.";
        type = lib.types.package;
        default = pkgs.zsh;
    };

    extraAlias = lib.mkOption {
        description = "Extra alias to set";
        type = lib.types.lines;
        default = "";
    };
    extraEnv = lib.mkOption {
        description = "Extra environment variables to set";
        type = lib.types.lines;
        default = "";
    };
    extraFunctions = lib.mkOption {
        description = "Extra functions to set";
        type = lib.types.lines;
        default = "";
    };
    extraOptions = lib.mkOption {
        description = "Extra settings to add to `zshrc.zsh`";
        type = lib.types.lines;
        default = "";
    };
    extraProfile = lib.mkOption {
        description = "Extra settings to add to `zprofile.zsh`";
        type = lib.types.lines;
        default = "";
    };
}

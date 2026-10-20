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
    extraFiles = lib.mkOption {
        description = ''
            Extra zsh files. Each attribute name is a file name (without `.zsh`) written to
            `~/.config/zsh/user/`, and its value is the content of that file.
            `main.zsh` sources every file there in alphabetical order, so prefix names
            (`10-foo`) to control the order. `env` and `profile` are sourced by zshenv and
            zprofile instead. A name that matches another option's file (`env`, `profile`,
            `alias`, `functions`, `options`) is appended to that option's content.
        '';
        type = lib.types.attrsOf lib.types.lines;
        default = { };
        example = lib.literalExpression ''
            {
                "10-fzf" = '''
                    source <(fzf --zsh)
                ''';
            }
        '';
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
    linkRcFiles = lib.mkOption {
        description = ''
            Link `zshenv`, `zshrc` and `zprofile` into `$HOME`. Turn off if you generate those
            yourself (e.g. Home Manager's `programs.zsh`); they then have to source
            `~/.config/zsh/{env,main,profile}.zsh`, as the dotfiles' own versions do.
        '';
        type = lib.types.bool;
        default = true;
    };
}

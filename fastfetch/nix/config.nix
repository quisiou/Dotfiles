# fastfetch/nix/config.nix


# Home Manager wiring for this module. `cfg` is `programs.dotfiles.modules.fastfetch`.
{ lib, config, cfg, ... }:

let
    home     = config.home.homeDirectory;
    dotsHome = config.programs.dotfiles.dotsHome;
in
{
    # home.file targets are relative to $HOME, so dotsHome has to live inside it
    assertions = lib.optional (cfg.templatePath != null) {
        assertion = lib.hasPrefix "${home}/" dotsHome;
        message = "programs.dotfiles.modules.fastfetch.templatePath needs programs.dotfiles.dotsHome to be inside your home directory";
    };

    home.packages = [ (lib.setPrio 0 cfg.package) ];

    # set_theme.py looks in dotsHome/templates before the repo's templates
    home.file = lib.mkIf (cfg.templatePath != null) {
        "${lib.removePrefix "${home}/" dotsHome}/templates/fastfetch.json".source = cfg.templatePath;
    };
}

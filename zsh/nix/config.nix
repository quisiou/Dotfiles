# zsh/nix/config.nix


# Home Manager wiring for this module. `cfg` is `programs.dotfiles.modules.zsh`.
{ lib, cfg, ... }:

let
    root      = ../.;       # zsh/
    configDir = ../config;  # zsh/config/

    # Same discovery as setup.sh's `*.zsh` globs
    zshFiles = dir: lib.attrNames (lib.filterAttrs
        (name: type: type == "regular" && lib.hasSuffix ".zsh" name)
        (builtins.readDir dir));

    # Only non-empty entries get a file. main.zsh sources every user/*.zsh except
    # env.zsh and profile.zsh, which the default env/profile files source themselves.
    # Entries that target the same file (e.g. extraAlias and extraFiles.alias) are concatenated.
    userFiles = lib.filterAttrs (_: text: text != "") (
        lib.zipAttrsWith (_: lib.concatStringsSep "\n") [
            {
                "alias.zsh"     = cfg.extraAlias;
                "env.zsh"       = cfg.extraEnv;
                "functions.zsh" = cfg.extraFunctions;
                "options.zsh"   = cfg.extraOptions;
                "profile.zsh"   = cfg.extraProfile;
            }
            (lib.mapAttrs' (name: text: lib.nameValuePair "${name}.zsh" text) cfg.extraFiles)
        ]
    );
in
{
    # tools.nix already installs the default zsh; same hiPrio trick as yazi and kitty
    home.packages = [ (lib.hiPrio cfg.package) ];

    # Managed here instead of letting setup.sh link them: setup.sh would link to the
    # store path of the first run and keep pointing there after updates.
    # setup.sh sees the existing links and skips them.
    home.file = lib.listToAttrs (map (name: {
        name = ".${lib.removeSuffix ".zsh" name}";
        value.source = root + "/${name}";
    }) (zshFiles root));

    xdg.configFile =
        lib.listToAttrs (map (name: {
            name = "zsh/${name}";
            value.source = configDir + "/${name}";
        }) (zshFiles configDir))
        // lib.mapAttrs' (name: text: lib.nameValuePair "zsh/user/${name}" { inherit text; }) userFiles;
}

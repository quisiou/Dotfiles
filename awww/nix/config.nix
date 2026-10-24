# awww/nix/config.nix


# Home Manager wiring for this module. `cfg` is `programs.dotfiles.modules.awww`.
{ lib, pkgs, config, cfg, ... }:

let
    home     = config.home.homeDirectory;
    dotsHome = config.programs.dotfiles.dotsHome;
    t        = cfg.settings.transition;

    # Environment variables to set as defaults; null (unset) keeps awww's own default
    env = lib.filterAttrs (_: v: v != null) {
        AWWW_TRANSITION          = t.type;
        AWWW_TRANSITION_STEP     = lib.mapNullable toString t.step;
        AWWW_TRANSITION_DURATION = lib.mapNullable toString t.duration;
        AWWW_TRANSITION_FPS      = lib.mapNullable toString t.fps;
        AWWW_TRANSITION_ANGLE    = lib.mapNullable toString t.angle;
        AWWW_TRANSITION_POS      = t.pos;
        AWWW_TRANSITION_BEZIER   = t.bezier;
        AWWW_TRANSITION_WAVE     = t.wave;
        AWWW_INVERT_Y            = lib.mapNullable lib.boolToString cfg.settings.invertY;
    };

    # awww with those variables as defaults (--set-default: your own environment still wins).
    # Without any, it is the plain package, the same store path tools.nix installs.
    # Only `awww` is wrapped; `awww-daemon` stays as it is.
    awww =
        if env == { } then cfg.package
        else pkgs.symlinkJoin {
            name = "${cfg.package.name}-defaults";
            paths = [ cfg.package ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
                wrapProgram $out/bin/awww ${lib.concatStringsSep " " (lib.mapAttrsToList
                    (k: v: "--set-default ${k} ${lib.escapeShellArg v}") env)}
            '';
        };
in
{
    # home.file targets are relative to $HOME, so dotsHome has to live inside it
    assertions = [{
        assertion = lib.hasPrefix "${home}/" dotsHome;
        message = "programs.dotfiles.modules.awww needs programs.dotfiles.dotsHome to be inside your home directory";
    }];

    # tools.nix already installs the default package; same setPrio trick as the other modules
    home.packages = [ (lib.setPrio 0 awww) ];

    # Managed here instead of letting setup.sh link them: setup.sh links each wallpaper into the
    # store, and those links go dangling after garbage collection (and it never replaces them).
    # Your own files in this folder are left alone.
    home.file."${lib.removePrefix "${home}/" dotsHome}/wallpapers" = {
        source = ../wallpapers;
        recursive = true;
    };
}

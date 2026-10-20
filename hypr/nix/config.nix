# hypr/nix/config.nix


# Home Manager wiring for this module. `cfg` is `programs.dotfiles.modules.hypr`.
{ lib, cfg, ... }:

let
    # Same convention as Home Manager's own hyprland module
    pluginPath = p: if lib.isDerivation p then "${p}/lib/lib${p.pname}.so" else toString p;

    # Plugins first, so extraConfig can configure them
    initLua =
        lib.concatMapStrings (p: ''
            hl.plugin.load("${pluginPath p}")
        '') cfg.plugins
        + cfg.extraConfig;

    # user/<file>.lua -> its content.
    # hyprland.lua requires every one of these, so all must exist even when empty.
    userFiles = {
        "init.lua"          = initLua;
        "env.lua"           = cfg.extraEnv;
        "variables.lua"     = cfg.extraVariables;
        "monitors.lua"      = cfg.extraMonitors;
        "look_and_feel.lua" = cfg.extraLookAndFeel;
        "input.lua"         = cfg.extraInput;
        "keybinds.lua"      = cfg.extraKeybinds;
        "windowrules.lua"   = cfg.extraWindowRules;
        "autostart.lua"     = cfg.extraAutostart;
    };
in
{
    xdg.configFile = {
        "hypr/hyprland.lua".source = ../hyprland.lua;
        "hypr/default".source      = ../config;
    } // lib.mapAttrs' (name: text: lib.nameValuePair "hypr/user/${name}" { inherit text; }) userFiles;
}

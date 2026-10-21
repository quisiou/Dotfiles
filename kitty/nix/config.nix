# kitty/nix/config.nix


# Home Manager wiring for this module. `cfg` is `programs.dotfiles.modules.kitty`.
{ lib, cfg, ... }:

{
    # Same hiPrio trick as yazi: tools.nix already installs the default kitty
    home.packages = [ (lib.setPrio 0 cfg.package) ];

    # kitty.conf is managed here instead of letting setup.sh link it. setup.sh
    # would link to whatever store path was current on the first run and keep
    # pointing there after later updates, so repo edits wouldn't reach it.
    # setup.sh sees the existing link and skips it.
    xdg.configFile."kitty/kitty.conf".source = ../kitty.conf;
    xdg.configFile."kitty/user.conf".text = cfg.extraConfig;
}

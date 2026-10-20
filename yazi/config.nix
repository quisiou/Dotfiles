# yazi/config.nix


# Home Manager wiring for this module. `cfg` is `programs.dotfiles.modules.yazi`.
{ lib, cfg, ... }:

{
    # hiPrio lets a custom `package` win without a collision; with the default
    # package both entries are the same store path.
    home.packages = [ (lib.hiPrio cfg.package) ];

    xdg.configFile."yazi/user/keymap.toml".text = cfg.extraKeymaps;
    xdg.configFile."yazi/user/yazi.toml".text   = cfg.extraOptions;
}

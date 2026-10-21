# fastfetch/nix/config.nix


# Home Manager wiring for this module. `cfg` is `programs.dotfiles.modules.fastfetch`.
{ lib, cfg, ... }:

{
    home.packages = [ (lib.setPrio 0 cfg.package) ];
}

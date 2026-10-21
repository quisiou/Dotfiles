# elysian_themes/nix/config.nix


# Home Manager wiring for this module.
{ lib, pkgs, config, ... }:

let
    tools = import ./tools.nix pkgs;
in
{
    # Re-apply the current theme so template changes take effect. It uses the script from
    # this source, not the link in dotsHome (which may point at an older store path), and
    # a failure here never aborts the switch.
    home.activation.elysianRerenderTheme = lib.hm.dag.entryAfter [ "dotfilesSetup" ] ''
        export ELYSIAN_DOTS_HOME="${config.programs.dotfiles.dotsHome}"
        export PATH="${lib.makeBinPath tools}:$PATH"
        $DRY_RUN_CMD python3 ${../.}/set_theme.py || echo "dotfiles: theme re-render failed (see above)"
    '';
}

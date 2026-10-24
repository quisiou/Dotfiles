# btop/nix/config.nix


# Home Manager wiring for this module. `cfg` is `programs.dotfiles.modules.btop`.
{ lib, pkgs, cfg, ... }:

let
    base  = builtins.readFile ../btop.conf;
    lines = lib.splitString "\n" base;

    # "key = value" lines only; comments and blank lines don't match
    keyOf = line:
        let m = builtins.match "([a-z_0-9]+) *= *.*" line;
        in if m == null then null else builtins.head m;

    render = v:
        if builtins.isBool v then lib.boolToString v
        else if builtins.isString v then "\"${v}\""
        else toString v;

    baseKeys = lib.filter (k: k != null) (map keyOf lines);
    unknown  = lib.filter (k: !(lib.elem k baseKeys)) (lib.attrNames cfg.extraConfig);

    patched = lib.concatStringsSep "\n" (map (line:
        let k = keyOf line;
        in if k != null && cfg.extraConfig ? ${k} then "${k} = ${render cfg.extraConfig.${k}}" else line
    ) lines);

    # With a preset, btop is wrapped so it always starts with `--preset N`.
    # Without one it is the plain package, the same store path tools.nix installs.
    btop =
        if cfg.preset == null then cfg.package
        else pkgs.symlinkJoin {
            name = "${cfg.package.name}-preset";
            paths = [ cfg.package ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
                wrapProgram $out/bin/btop --add-flags "--preset ${toString cfg.preset}"
            '';
        };
in
{
    assertions = [{
        assertion = unknown == [ ];
        message = "programs.dotfiles.modules.btop.extraConfig: keys not in btop.conf: ${toString unknown}";
    }];

    # tools.nix already installs the default package; same setPrio trick as the other modules
    home.packages = [ (lib.setPrio 0 btop) ];

    # Managed here instead of letting setup.sh link it: setup.sh would link to the store path
    # of the first run and keep pointing there. With no settings it equals the repo's file.
    xdg.configFile."btop/btop.conf".text = patched;
}

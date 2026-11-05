# yazi/nix/config.nix


# Home Manager wiring for this module. `cfg` is `programs.dotfiles.modules.yazi`.
{ lib, cfg, ... }:

let
    fetchPlugin = p:
        let repo = fetchGit { inherit (p) url rev; allRefs = true; };
        in if p.subdir == null then repo else repo + "/${p.subdir}";

    pluginFiles = lib.mapAttrs' (name: p:
        if p.url != null
        then lib.nameValuePair "yazi/plugins/${name}.yazi"          { source = fetchPlugin p; }
        else lib.nameValuePair "yazi/plugins/${name}.yazi/main.lua" { text = p.text; }
    ) cfg.extraPlugins;

    plugins = lib.attrValues cfg.extraPlugins;

    repoPlugins = lib.attrNames (builtins.readDir ../plugins);

    repoPluginFiles = lib.mapAttrs' (name: _:
        lib.nameValuePair "yazi/plugins/${name}" { source = lib.cleanSource (../plugins + "/${name}"); }
    ) (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../plugins));
    clashes = lib.filter (name: lib.elem "${name}.yazi" repoPlugins) (lib.attrNames cfg.extraPlugins);
in
{

    assertions = [
        {
            assertion = clashes == [ ];
            message = "programs.dotfiles.modules.yazi.extraPlugins: names clash with the repo's plugins/: ${toString clashes}";
        }
        {
            assertion = lib.all (p: (p.url != null) != (p.text != "")) plugins;
            message = "programs.dotfiles.modules.yazi.extraPlugins: each plugin needs exactly one of `url` or `text`";
        }
        {
            assertion = lib.all (p: p.url == null || p.rev != null) plugins;
            message = "programs.dotfiles.modules.yazi.extraPlugins: plugins with `url` need a `rev`";
        }
    ];

    # hiPrio lets a custom `package` win without a collision; with the default
    # package both entries are the same store path.
    home.packages = [ (lib.setPrio 0 cfg.package) ];

    xdg.configFile = {
        "yazi/user/keymap.toml".text = cfg.extraKeymaps;
        "yazi/user/yazi.toml".text   = cfg.extraOptions;
    } // repoPluginFiles // pluginFiles;
}

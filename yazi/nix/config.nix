# yazi/nix/config.nix


# Home Manager wiring for this module. `cfg` is `programs.dotfiles.modules.yazi`.
{ lib, cfg, ... }:

let
    pluginSource = p:
        if p.subdir == null then p.src else "${p.src}/${p.subdir}";

    pluginFiles = lib.mapAttrs' (name: p:
        if p.src != null
        then lib.nameValuePair "yazi/plugins/${name}.yazi"          { source = pluginSource p; }
        else lib.nameValuePair "yazi/plugins/${name}.yazi/main.lua" { text = p.text; }
    ) cfg.extraPlugins;

    plugins = lib.attrValues cfg.extraPlugins;

    # one symlink per repo plugin dir (not per file); cleanSource drops the submodules' `.git` file
    repoPluginFiles = lib.mapAttrs' (name: _:
        lib.nameValuePair "yazi/plugins/${name}" { source = lib.cleanSource (../plugins + "/${name}"); }
    ) (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../plugins));

    # A clash would be a confusing Home Manager conflict, so fail early with a clear message
    repoPlugins = lib.attrNames (builtins.readDir ../plugins);
    clashes = lib.filter (name: lib.elem "${name}.yazi" repoPlugins) (lib.attrNames cfg.extraPlugins);
in
{
    assertions = [
        {
            assertion = clashes == [ ];
            message = "programs.dotfiles.modules.yazi.extraPlugins: names clash with the repo's plugins/: ${toString clashes}";
        }
        {
            assertion = lib.all (p: (p.src != null) != (p.text != "")) plugins;
            message = "programs.dotfiles.modules.yazi.extraPlugins: each plugin needs exactly one of `src` or `text`";
        }
        {
            assertion = lib.all (p: p.subdir == null || p.src != null) plugins;
            message = "programs.dotfiles.modules.yazi.extraPlugins: `subdir` only makes sense together with `src`";
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

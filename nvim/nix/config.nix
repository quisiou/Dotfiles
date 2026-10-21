# nvim/nix/config.nix


# Home Manager wiring for this module. `cfg` is `programs.dotfiles.modules.nvim`.
{ lib, pkgs, config, cfg, ... }:

let
    # lua/user/<file>: only non-empty options get a file, since the hooks check for existence
    userFiles = lib.filterAttrs (_: text: text != "") {
        "user/options.lua" = cfg.extraOptions;
        "user/keymaps.lua" = cfg.extraKeymaps;
    };

    # extra plugin specs sit beside the repo's, in lua/plugins/
    pluginFiles = lib.mapAttrs' (name: text: lib.nameValuePair "plugins/${name}.lua" text) cfg.extraPlugins;

    # A clash would be a confusing Home Manager conflict, so fail early with a clear message
    repoPlugins = lib.attrNames (builtins.readDir ../lua/plugins);
    clashes = lib.filter (name: lib.elem "${name}.lua" repoPlugins) (lib.attrNames cfg.extraPlugins);

    nvim =
        if cfg.extraPackages == [ ] then cfg.package
        else pkgs.symlinkJoin {
            name = "${cfg.package.name}-wrapped";
            paths = [ cfg.package ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
                wrapProgram $out/bin/nvim --suffix PATH : ${lib.makeBinPath cfg.extraPackages}
            '';
        };
in
{
    assertions = [{
        assertion = clashes == [ ];
        message = "programs.dotfiles.modules.nvim.extraPlugins: names clash with the repo's lua/plugins/: ${toString clashes}";
    }];

    home.packages = [ (lib.setPrio 0 nvim) ];

    # Managed here instead of letting setup.sh link them: setup.sh would link to the
    # store path of the first run and keep pointing there after updates.
    # setup.sh sees the existing links and skips them.
    xdg.configFile = {
        "nvim/init.lua".source = ../init.lua;
        "nvim/colors".source   = ../colors;

        # recursive: lua/ and lua/plugins/ become real directories of per-file links,
        # so user/ and the extra plugin specs can live beside the repo's files
        "nvim/lua" = { source = ../lua; recursive = true; };

        # lazy.nvim rewrites this on install/update/restore
        "nvim/lazy-lock.json".source =
            if cfg.lockfile == null
            then ../lazy-lock.json
            else config.lib.file.mkOutOfStoreSymlink cfg.lockfile;
    } // lib.mapAttrs' (name: text: lib.nameValuePair "nvim/lua/${name}" { inherit text; }) (userFiles // pluginFiles);
}

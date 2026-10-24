# flake.nix


{
    description = "Random guy's dotfiles for hyprland setup";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = { self, nixpkgs, flake-utils }:
        let
            mkDotfilesLib = { pkgs, config, lib }:
                let
                    moduleNames = builtins.attrNames (
                        lib.filterAttrs
                            (name: type: type == "directory" && builtins.pathExists (self + "/${name}/setup.sh"))
                            (builtins.readDir self)
                    );

                    # A module's nix-side files live in <module>/nix/
                    nixFile = name: file: self + "/${name}/nix/${file}";

                    getTools = name:
                        let
                            toolsFile = nixFile name "tools.nix";
                        in
                            if builtins.pathExists toolsFile then import toolsFile pkgs else [];

                    getDepsDirect = name:
                        let
                            depsFile = nixFile name "deps.nix";
                        in
                            if builtins.pathExists depsFile then import depsFile else [];

                    getDeps = name:
                        let
                            direct = getDepsDirect name;
                            nested = builtins.concatMap getDeps direct;
                        in
                            lib.unique (nested ++ direct);

                    # Call a file's function with only the arguments it declares
                    callWith = file: args:
                        let f = import file; in f (builtins.intersectAttrs (lib.functionArgs f) args);
                    getExtraOptions = name:
                        let
                            optsFile = nixFile name "options.nix";
                        in
                            if builtins.pathExists optsFile
                            then callWith optsFile { inherit lib config pkgs; }
                            else {};

                    hasModuleConfig = name: builtins.pathExists (nixFile name "config.nix");

                    getModuleConfig = name: cfg:
                        if hasModuleConfig name
                        then callWith (nixFile name "config.nix") { inherit lib config pkgs cfg; }
                        else {};
                in {
                    inherit moduleNames getTools getDepsDirect getDeps getExtraOptions hasModuleConfig getModuleConfig;
                };
        in
            (flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
                let
                    pkgs = import nixpkgs {
                        inherit system;
                        config.allowUnfree = true;
                    };
                    dl = mkDotfilesLib { inherit pkgs; config = {}; lib = pkgs.lib; };
                    inherit (dl) moduleNames getTools getDeps;

                    mkApp = name: {
                        type = "app";
                        program = "${pkgs.writeShellApplication {
                            name = "setup-${name}";
                            runtimeInputs = getTools name ++ builtins.concatMap getTools (getDeps name);
                            text = ''
                                export ELYSIAN_DOTS_HOME="''${ELYSIAN_DOTS_HOME:-$HOME/.local/share/elysian-dots}"

                                ${builtins.concatStringsSep "\n" (map (dep: ''
                                    if [ -e "$HOME/.config/${dep}" ]; then
                                        echo "── Skipping dependency '${dep}': already set up ──"
                                    else
                                        echo "── Running dependency: ${dep} ──"
                                        (cd "${self}/${dep}" && ./setup.sh)
                                    fi
                                '') (getDeps name))}

                                cd "${self}/${name}"
                                ./setup.sh
                            '';
                        }}/bin/setup-${name}";
                    };

                    mkShell = name: pkgs.mkShell {
                        name = "dotfiles-${name}";
                        buildInputs = getTools name ++ builtins.concatMap getTools (getDeps name);
                        shellHook = ''
                            echo "Dev shell for '${name}' (+ deps: ${toString (getDeps name)})."
                        '';
                    };

                    perModuleApps   = builtins.listToAttrs (map (n: { name = n; value = mkApp n; }) moduleNames);
                    perModuleShells = builtins.listToAttrs (map (n: { name = n; value = mkShell n; }) moduleNames);
                in {
                    apps = perModuleApps // {
                        default = {
                            type = "app";
                            program = "${pkgs.writeShellApplication {
                                name = "dotfiles-setup-all";
                                runtimeInputs = builtins.concatMap getTools moduleNames;
                                text = ''
                                    export ELYSIAN_DOTS_HOME="''${ELYSIAN_DOTS_HOME:-$HOME/.local/share/elysian-dots}"
                                    cd "${self}" && ./setup.sh
                                '';
                            }}/bin/dotfiles-setup-all";
                        };
                    };

                    devShells = perModuleShells // {
                        default = pkgs.mkShell {
                            buildInputs = builtins.concatMap getTools moduleNames;
                        };
                    };
                }
            )) // {
                homeManagerModules.default = { config, lib, pkgs, ... }:
                    let
                        dl = mkDotfilesLib { inherit pkgs lib config; };
                        inherit (dl) moduleNames getTools getDeps getExtraOptions hasModuleConfig getModuleConfig;

                        cfg = config.programs.dotfiles;

                        enabledModules = builtins.filter (n: cfg.modules.${n}.enable) moduleNames;
                        selected = lib.unique (builtins.concatMap (m: getDeps m ++ [ m ]) enabledModules);

                        # Static on purpose: this is the list spine of mkMerge below, so it must not
                        # depend on config values (e.g. `selected`) or evaluation recurses infinitely.
                        configModules = builtins.filter hasModuleConfig moduleNames;
                    in {
                        options.programs.dotfiles = {
                            enable = lib.mkEnableOption "personal dotfiles";

                            defaultEnabled = lib.mkOption {
                                type = lib.types.bool;
                                default = false;
                                description = ''
                                    Default for every module's `enable`. With false you list the modules you
                                    want (`modules.<name>.enable = true`); with true every module is on and
                                    you can switch individual ones off (`modules.<name>.enable = false`).
                                '';
                            };

                            dotsHome = lib.mkOption {
                                type = lib.types.str;
                                default = "${config.xdg.dataHome}/elysian-dots";
                                description = ''
                                    Directory holding the shared dots data (active-theme, color-themes, wallpapers...).
                                    Exported as ELYSIAN_DOTS_HOME.
                                '';
                            };

                            modules = lib.genAttrs moduleNames (name: {
                                enable = lib.mkOption {
                                    description = "Whether to set up the '${name}' dotfiles module and the modules it depends on.";
                                    type = lib.types.bool;
                                    default = cfg.defaultEnabled;
                                };
                            } // (getExtraOptions name));
                        };

                        config = lib.mkIf cfg.enable (lib.mkMerge ([
                            {
                                home.sessionVariables.ELYSIAN_DOTS_HOME = cfg.dotsHome;
                                systemd.user.sessionVariables.ELYSIAN_DOTS_HOME = cfg.dotsHome;

                                home.packages = builtins.concatMap getTools selected;

                                # After linkGeneration so files declared by config.nix are already in place
                                home.activation.dotfilesSetup = lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" ] (
                                    ''
                                        export ELYSIAN_DOTS_HOME="${cfg.dotsHome}"
                                        export PATH="${lib.makeBinPath (builtins.concatMap getTools selected)}:$PATH"
                                    '' + builtins.concatStringsSep "\n" (map (m:
                                        if hasModuleConfig m then ''
                                            echo "dotfiles: setting up ${m}"
                                            (cd "${self}/${m}" && $DRY_RUN_CMD ./setup.sh)
                                        '' else ''
                                            if [ -e "$HOME/.config/${m}" ]; then
                                                echo "dotfiles: skipping ${m} (already set up)"
                                            else
                                                echo "dotfiles: setting up ${m}"
                                                (cd "${self}/${m}" && $DRY_RUN_CMD ./setup.sh)
                                            fi
                                        '') selected)
                                );
                            }
                        ] ++ map (m: lib.mkIf (builtins.elem m selected) (getModuleConfig m cfg.modules.${m})) configModules));
                    };
            };
}

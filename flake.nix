# flake.nix


{
    description = "Random guy's dotfiles for hyprland setup";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = { self, nixpkgs, flake-utils }:
        let
            mkDotfilesLib = { pkgs, lib }:
                let
                    moduleNames = builtins.attrNames (
                        lib.filterAttrs
                            (name: type: type == "directory" && builtins.pathExists (self + "/${name}/setup.sh"))
                            (builtins.readDir self)
                    );

                    getTools = name:
                        let
                            toolsFile = self + "/${name}/tools.nix";
                        in
                            if builtins.pathExists toolsFile then import toolsFile pkgs else [];

                    getDepsDirect = name:
                        let
                            depsFile = self + "/${name}/deps.nix";
                        in
                            if builtins.pathExists depsFile then import depsFile else [];

                    getDeps = name:
                        let
                            direct = getDepsDirect name;
                            nested = builtins.concatMap getDeps direct;
                        in
                            lib.unique (nested ++ direct);

                    getExtraOptions = name:
                        let
                            optsFile = self + "/${name}/options.nix";
                        in
                            if builtins.pathExists optsFile then import optsFile { inherit lib pkgs; } else {};
                in {
                    inherit moduleNames getTools getDepsDirect getDeps getExtraOptions;
                };
        in
            (flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
                let
                    pkgs = import nixpkgs {
                        inherit system;
                        config.allowUnfree = true;
                    };
                    dl = mkDotfilesLib { inherit pkgs; lib = pkgs.lib; };
                    inherit (dl) moduleNames getTools getDeps;

                    mkApp = name: {
                        type = "app";
                        program = "${pkgs.writeShellApplication {
                            name = "setup-${name}";
                            runtimeInputs = getTools name;
                            text = ''
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
                                text = ''cd "${self}" && ./setup.sh'';
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
                        dl = mkDotfilesLib { inherit pkgs lib; };
                        inherit (dl) moduleNames getTools getDeps getExtraOptions;

                        cfg = config.programs.dotfiles;

                        enabledDirectly = builtins.filter (n: cfg.modules.${n}.enable) moduleNames;
                        activeModules = if cfg.allEnabled then moduleNames else enabledDirectly;
                        selected = lib.unique (builtins.concatMap (m: getDeps m ++ [ m ]) activeModules);
                    in {
                        options.programs.dotfiles = {
                            enable = lib.mkEnableOption "personal dotfiles";

                            allEnabled = lib.mkOption {
                                type = lib.types.bool;
                                default = true;
                                description = "If true, every discovered module is activated, ignoring modules.<name>.enable.";
                            };

                            modules = lib.mkOption {
                                type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
                                    options = {
                                        enable = lib.mkEnableOption "the '${name}' dotfiles module";
                                    } // (getExtraOptions name);
                                }));
                                default = lib.genAttrs moduleNames (_: {});
                                description = "Per-module dotfiles configuration.";
                            };
                        };

                        config = lib.mkIf cfg.enable {
                            home.packages = builtins.concatMap getTools selected;

                            home.activation.dotfilesSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] (
                                builtins.concatStringsSep "\n" (map (m: ''
                                    if [ -e "$HOME/.config/${m}" ]; then
                                        echo "dotfiles: skipping ${m} (already set up)"
                                    else
                                        echo "dotfiles: setting up ${m}"
                                        (cd "${self}/${m}" && ./setup.sh)
                                    fi
                                '') selected)
                            );
                        };
                    };
            };
}

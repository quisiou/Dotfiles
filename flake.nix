# flake.nix


{
    description = "Random guy's dotfiles for hyprland setup";

    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    inputs.flake-utils.url = "github:numtide/flake-utils";

    outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
        let
            pkgs = import nixpkgs {
                inherit system;
                config.allowUnfree = true;
            };

            moduleNames = builtins.attrNames (
                pkgs.lib.filterAttrs
                    (name: type: type == "directory" && builtins.pathExists (self + "/${name}/setup.sh"))
                    (builtins.readDir self)
            );

            getTools = name:
                let toolsFile = self + "/${name}/tools.nix";
                in  if builtins.pathExists toolsFile
                    then import toolsFile pkgs
                    else [];

            getDeps = name:
                let depsFile = self + "/${name}/deps.nix";
                in  if builtins.pathExists depsFile
                    then import depsFile
                    else [];

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
                shellHook = ''echo "Dev shell for '${name}' (+ deps: ${toString (getDeps name)})."'';
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
    );
}

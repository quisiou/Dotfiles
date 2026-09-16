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

            mkApp = name: {
                type = "app";
                program = "${pkgs.writeShellApplication {
                    name = "setup-${name}";
                    runtimeInputs = getTools name;
                    text = ''
                        cd "${self}/${name}"
                        ./setup.sh
                    '';
                }}/bin/setup-${name}";
            };

            mkShell = name: pkgs.mkShell {
                name = "dotfiles-${name}";
                buildInputs = getTools name;
                shellHook = ''
                    echo "Dev shell for '${name}'. Run ./setup.sh in ${self}/${name} to apply, or just poke around."
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
    );
}

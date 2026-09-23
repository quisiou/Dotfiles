# fastfetch/options.nix


{ lib, pkgs }:

let
    jsonFormat = pkgs.formats.json { };
in
{
    package = lib.mkOption {
        description = "The fastfetch package to use.";
        type = lib.types.package;
        default = pkgs.fastfetch;
    };

    settings = lib.mkOption {
        description = ''
            Fastfetch internal settings (check fastfetch's github repository for documentation).
            These can be changed later using the provided script or by manually editing the files.
        '';
        type = lib.types.submodule ({ config, ... }: {
            options = {
                configPath = lib.mkOption {
                    description = "Path to the config file to be used.";
                    type = lib.types.str;
                    default = "${config.xdg.configHome}/fastfetch/config.jsonc";
                };
                display = lib.mkOption {
                    description = "Display options as nix attribute set (serialized to JSON).";
                    type = jsonFormat.type;
                    default = { };
                    example = {
                        separator = ":";
                        color = {
                            keys = "blue";
                            title = "red";
                        };
                        key = {
                            width = 12;
                            type = "string";
                        };
                        bar = {
                            width = 10;
                            char = {
                                elapsed = "■";
                                total = "-";
                            };
                        };
                        percent = {
                            type = 9;
                            color = {
                                green = "green";
                                yellow = "light_yellow";
                                red = "light_red";
                            };
                        };
                    };
                };
                general = lib.mkOption {
                    description = "General options as nix attribute set (serialized to JSON).";
                    type = jsonFormat.type;
                    default = { };
                    example = {
                        thread = true;
                        processingTimeout = 5000;
                        detectVersion = true;
                        playerName = "";
                        dsForceDrm = false;
                    };
                };
                logo = lib.mkOption {
                    description = "Logo options as nix attribute set (serialized to JSON).";
                    type = jsonFormat.type;
                    default = { };
                    example = {
                        type = "auto";
                        source = "arch";
                        width = 65;
                        height = 35;
                        padding = {
                            top = 0;
                            left = 0;
                            right = 2;
                        };
                        color = {
                            "2" = "green";
                            "1" = "blue";
                        };
                    };
                };
                modules = lib.mkOption {
                    description = "Module options as nix attribute set (serialized to JSON).";
                    type = jsonFormat.type;
                    default = [ ];
                    example = [
                        "title"
                        "separator"
                        {
                            type = "os";
                            key = "OS";
                            keyColor = "blue";
                            format = "{name} {version}";
                        }
                        {
                            type = "kernel";
                            key = "Kernel";
                        }
                        {
                            type = "memory";
                            key = "Memory";
                            percent = {
                                type = 3;
                                green = 30;
                                yellow = 70;
                            };
                        }
                    ];
                };
            };
        });
        default = { };
    };
}

# elysian_themes/tools.nix


pkgs: with pkgs; [ (python3.withPackages (ps: with ps; [ jinja2 ])) ]

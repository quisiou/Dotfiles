# quickshell/tools.nix


pkgs: with pkgs; [
    quickshell
    libnotify
    inotify-tools
    cava
    awww
    (python3.withPackages (ps: with ps; [ jinja2 ]))
]

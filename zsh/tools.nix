# zsh/tools.nix


pkgs: with pkgs; [
    zsh
    fzf
    zoxide
    ripgrep
    fd
    file
    git
    (python3.withPackages (ps: with ps; [ jinja2 ]))
]

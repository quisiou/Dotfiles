# yazi/tools.nix


pkgs: with pkgs; [
    (yazi.override { _7zz = _7zz-rar; })
    file
    ffmpeg
    fd
    ripgrep
    fzf
    zoxide
    resvg
    imagemagick
    _7zz-rar
    jq poppler
    exiftool
    git
    lazygit
]

# nvim/tools.nix


pkgs: with pkgs; [
    neovim
    ripgrep
    fzf
    fd
    git
    lazygit
    texliveMedium
    gcc clang-tools
    tree-sitter
    lua-language-server
    vim-language-server
    nixd
    marksman
    bash-language-server
    shellcheck
    basedpyright ruff
    (let
        qmlImportPath = lib.makeSearchPath "lib/qt-6/qml" [ qt6.qtdeclarative quickshell ];
    in symlinkJoin {
        name = "qmlls";
        paths = [ qt6.qtdeclarative ];
        buildInputs = [ makeWrapper ];
        postBuild = ''wrapProgram $out/bin/qmlls --set QML2_IMPORT_PATH "${qmlImportPath}"'';
    })
]

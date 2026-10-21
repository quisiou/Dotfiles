# fastfetch/nix/options.nix


{ lib, pkgs }:

{
    package = lib.mkOption {
        description = "The fastfetch package to use.";
        type = lib.types.package;
        default = pkgs.fastfetch;
    };
    templatePath = lib.mkOption {
        description = ''
            Your own Jinja template for the generated `fastfetch.toml`, used instead of the repo's.
            It is rendered with the current theme (`colors`, `meta`), so it follows theme switches.
            Start from a copy of `elysian_themes/templates/fastfetch.toml`. Use a path literal
            inside your flake (e.g. `./templates/fastfetch.toml`), not a string.
        '';
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = lib.literalExpression "./templates/fastfetch.toml";
    };
}

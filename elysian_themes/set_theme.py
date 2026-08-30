# elysian_themes/set_theme.py


from sys import argv
from pathlib import Path
import tomllib
import subprocess
from jinja2 import Environment, FileSystemLoader


def print_usage():
    print("Usage:")
    print("\tpython3 set_theme.py <toml-theme-file>\n")
    print("Example:")
    print("\tpython3 set_theme.py ~/.config/elysian_themes/themes/default/TokyoCarbon.toml")


def parse_toml(toml_path: Path) -> dict[str, dict[str, str]]:
    if not toml_path.exists():
        raise FileNotFoundError(f"File {str(toml_path)} does not exist.")

    with open(toml_path, "rb") as f:
        data = tomllib.load(f)

    return data


def lua_format(config_dir: Path, theme: dict[str, dict[str, str]]) -> None:
    filepath: Path = config_dir / "colors.lua"

    with open(filepath, "w") as f:
        f.write(f"-- elysian_themes/active_theme/{filepath.name}\n\n\n")
        f.write("return {")
        for k1, v1 in theme.items():
            if k1 == "meta":
                continue

            f.write(f"\n\t{k1} = {{\n")
            for k2, v2 in v1.items():
                f.write(f"\t\t{k2:<20} = \"{v2}\",\n")
            f.write("\t},\n")

        f.write("}\n")


def template_replace(config_dir: Path, name: str, theme: dict[str, dict[str, str]], env: Environment) -> None:
    filepath: Path = config_dir / name
    template = env.get_template(name)
    output = template.render(colors=theme["colors"], meta=theme["meta"]).replace(
        f"elysian_themes/templates/{name}",
        f"elysian_themes/active_theme/{name}"
    )
    filepath.write_text(output + '\n')


if __name__ == "__main__":
    argc: int = len(argv)
    if argc != 2:
        print_usage()
        exit(1)

    root_dir: Path = Path(__file__).resolve().parent

    selected_theme: dict[str, dict[str, str]] = parse_toml(Path(argv[1]).resolve())
    fallback_theme: dict[str, dict[str, str]] = parse_toml(
        (Path.home() / ".config" / "elysian_themes" / "themes" / "default" / "TokyoCarbon.toml").resolve()
    )

    theme: dict[str, dict[str, str]] = {
        k: fallback_theme.get(k, {}) | selected_theme.get(k, {})
        for k in fallback_theme
    }

    config_dir: Path = (Path.home() / ".config" / "elysian_themes" / "active_theme").resolve()
    config_dir.mkdir(exist_ok=True)

    # Create the template files for all utilities
    lua_format(config_dir, theme)

    # # For files that are actually templates, use Jinja2
    env = Environment(loader=FileSystemLoader(root_dir / "templates/"))
    env.filters["rgba"] = lambda color, a: f"{color}{a}"

    template_replace(config_dir, "kitty.conf",      theme, env)
    template_replace(config_dir, "yazi.toml",       theme, env)
    template_replace(config_dir, "starship.toml",   theme, env)
    template_replace(config_dir, "fastfetch.json",  theme, env)

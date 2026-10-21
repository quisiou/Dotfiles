# elysian_themes/set_theme.py


from sys import argv, stderr
from pathlib import Path
import tomllib
import os
from jinja2 import Environment, FileSystemLoader, TemplateError


def print_usage():
    print("Usage:")
    print("\tpython3 set_theme.py [<toml-theme-file>]\n")
    print("Without a file, the current theme is rendered again (e.g. after editing a template).\n")
    print("Example:")
    print("\tpython3 set_theme.py ~/.local/share/elysian-dots/color-themes/Elysian.toml")


def parse_toml(toml_path: Path) -> dict[str, dict[str, str]]:
    if not toml_path.exists():
        raise FileNotFoundError(f"File {str(toml_path)} does not exist.")

    with open(toml_path, "rb") as f:
        data = tomllib.load(f)

    return data


def lua_format(config_dir: Path, theme: dict[str, dict[str, str]]) -> None:
    filepath: Path = config_dir / "colors.lua"

    lines = [f"-- elysian_themes/active_theme/{filepath.name}\n\n\n", "return {"]
    for k1, v1 in theme.items():
        if k1 == "meta":
            continue

        lines.append(f"\n\t{k1} = {{\n")
        for k2, v2 in v1.items():
            lines.append(f"\t\t{k2:<20} = \"{v2}\",\n")
        lines.append("\t},\n")
    lines.append("}\n")

    text = "".join(lines)
    if filepath.exists() and filepath.read_text() == text:
        return
    filepath.write_text(text)


def template_replace(config_dir: Path, name: str, theme: dict[str, dict[str, str]], env: Environment) -> None:
    filepath: Path = config_dir / name
    try:
        output = env.get_template(name).render(colors=theme["colors"], meta=theme["meta"]).replace(
            f"elysian_themes/templates/{name}",
            f"elysian_themes/active_theme/{name}"
        )
    except TemplateError as e:
        print(f"warning: could not render {name}, keeping the previous file: {e}", file=stderr)
        return

    text = output + "\n"
    if filepath.exists() and filepath.read_text() == text:
        return                      # unchanged: don't touch the file (no needless reloads)
    filepath.write_text(text)


if __name__ == "__main__":
    argc: int = len(argv)
    if argc > 2:
        print_usage()
        exit(1)

    root_dir: Path = Path(__file__).resolve().parent
    dots_home: Path = Path(os.getenv("ELYSIAN_DOTS_HOME"))
    config_dir: Path = (dots_home / "active-theme").resolve()
    config_dir.mkdir(exist_ok=True)
    current_file: Path = config_dir / ".current"

    if argc == 2:
        # abspath, not resolve(): keep the stable symlink path, not a store path that goes stale
        selected_path = Path(os.path.abspath(argv[1]))
    elif current_file.exists():
        selected_path = Path(current_file.read_text().strip())
    else:
        print("No current theme recorded yet; run once with a theme file:")
        print_usage()
        exit(0)

    selected_theme = parse_toml(selected_path)
    fallback_theme = parse_toml((dots_home / "color-themes" / "Elysian.toml").resolve())

    theme: dict[str, dict[str, str]] = {
        k: fallback_theme.get(k, {}) | selected_theme.get(k, {})
        for k in fallback_theme
    }

    # Create the template files for all utilities
    lua_format(config_dir, theme)

    # # For files that are actually templates, use Jinja2
    env = Environment(loader=FileSystemLoader([str(dots_home / "templates"), str(root_dir / "templates")]))
    env.filters["rgba"] = lambda color, a: f"{color}{a}"

    template_replace(config_dir, "btop.theme",  theme, env)
    template_replace(config_dir, "fastfetch.json",  theme, env)
    template_replace(config_dir, "kitty.conf",      theme, env)
    template_replace(config_dir, "starship.toml",   theme, env)
    template_replace(config_dir, "yazi.toml",       theme, env)

    current_file.write_text(f"{selected_path}\n")

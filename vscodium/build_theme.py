# VSCodium/build_theme.py


from sys import argv
import os
from pathlib import Path
import tomllib
from jinja2 import Environment, FileSystemLoader


def print_usage():
    print("Usage:")
    print("\tpython3 build_theme.py <toml-theme-file> [<destination-directory>]\n")
    print("Example:")
    print("\tpython3 build_theme.py ~/.local/share/elysian-dots/color-themes/Elysian.toml ~/MyVSCodiumThemes/\n")
    print("Default value for <destination-directory> is ~/.local/share/elysian-dots/vscodium/themes")


def parse_toml(toml_path: Path) -> dict[str, dict[str, str]]:
    if not toml_path.exists():
        raise FileNotFoundError(f"File {str(toml_path)} does not exist.")

    with open(toml_path, "rb") as f:
        data = tomllib.load(f)

    return data


if __name__ == "__main__":
    argc: int = len(argv)
    if argc < 2 or argc > 3:
        print_usage()
        exit(1)

    script_dir: Path = Path(__file__).resolve().parent
    dest_dir: Path = Path(os.getenv("ELYSIAN_DOTS_HOME"), "vscodium", "themes") if argc == 2 else Path(argv[2]).resolve()

    dest_dir.mkdir(parents=True, exist_ok=True)

    selected_theme: dict[str, dict[str, str]] = parse_toml(Path(argv[1]).resolve())
    fallback_theme: dict[str, dict[str, str]] = parse_toml(
        Path(os.getenv("ELYSIAN_DOTS_HOME"), "color-themes", "Elysian.toml")
    )

    theme: dict[str, dict[str, str]] = {
        k: fallback_theme.get(k, {}) | selected_theme.get(k, {})
        for k in fallback_theme
    }

    env = Environment(loader=FileSystemLoader(script_dir))
    env.filters["rgba"] = lambda color, a: f"{color}{a}"

    f = dest_dir / f"{theme['meta']['id']}-color-theme.json"
    f.write_text(env.get_template("template.json").render(colors=theme["colors"], meta=theme["meta"]) + '\n')

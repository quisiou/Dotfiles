# VSCodium/build_package.py


from pathlib import Path
from sys import argv
import json

DEFAULT_DIR = Path.home() / ".local" / "share" / "elysian-dots" / "vscodium"
THEMES_SUBDIR = "themes"


def print_usage():
    print("Usage:")
    print("\tpython3 build_package.py [<extension-directory>]\n")
    print("Example:")
    print("\tpython3 build_package.py ~/MyVSCodiumExtension/\n")
    print(f"Default <extension-directory> is {DEFAULT_DIR}")
    print(f"Themes are read from <extension-directory>/{THEMES_SUBDIR}/")
    print("package.json is written to <extension-directory>/")


def get_themes_info(root_dir: Path) -> list[dict[str, str]]:
    themes: list[dict[str, str]] = []
    for t in sorted((root_dir / THEMES_SUBDIR).glob("*-color-theme.json")):
        with open(t, "r", encoding="utf-8") as f:
            theme_data = json.load(f)

        theme_type = theme_data.get("type", "dark")
        ui_theme = "hc-black" if theme_type == "hc" else f"vs-{theme_type}"

        themes.append({
            "label": theme_data.get("name", t.stem),
            "uiTheme": ui_theme,
            "path": f"./{THEMES_SUBDIR}/{t.name}",
        })

    return themes


if __name__ == "__main__":
    if len(argv) > 2:
        print_usage()
        exit(1)

    root_dir = DEFAULT_DIR if len(argv) == 1 else Path(argv[1]).expanduser().resolve()
    (root_dir / THEMES_SUBDIR).mkdir(parents=True, exist_ok=True)

    package_json: dict = {
        "name": "elysian-color-themes",
        "displayName": "Elysian Themes",
        "description": "Color themes for my dotfiles",
        "publisher": "quisiou",
        "version": "0.1.0",
        "private": True,
        "engines": {"vscode": "^1.50.0"},
        "categories": ["Themes"],
        "contributes": {"themes": get_themes_info(root_dir)},
        "repository": {
            "type": "git",
            "url": "https://github.com/quisiou/Dotfiles.git",
            "directory": "vscodium",
        },
    }

    out = root_dir / "package.json"
    out.write_text(json.dumps(package_json, indent=4) + "\n", encoding="utf-8")
    print(f"Wrote {out} ({len(package_json['contributes']['themes'])} themes)")

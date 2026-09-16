# VSCodium/build_package.py


from pathlib import Path
from sys import argv
import json


def print_usage():
    print("Usage:")
    print("\tpython3 build_package.py [<json-files-location>]\n")
    print("Example:")
    print("\tpython3 build_package.py ~/MyVSCodiumThemes/themes/\n")
    print("Default value for <json-files-location> is ~/.config/vscodium/themes/")


def get_themes_info(theme_dir: Path, root_dir: Path) -> list[dict[str, str]]:
    themes: list[dict[str, str]] = []
    print(str(theme_dir))
    for t in theme_dir.iterdir():
        print(str(t))
        if not t.is_file():
            continue

        with open(t, "r") as f:
            theme_data = json.load(f)

        theme_type = theme_data.get("type", None)

        relative_path = t.resolve().relative_to(root_dir.resolve())

        themes.append({
            "label": theme_data.get("name", "Unknown"),
            "uiTheme": f"vs-{theme_type if theme_type is not None else 'dark'}",
            "path": str(relative_path)
        })

    return themes


if __name__ == "__main__":
    argc: int = len(argv)
    if argc < 1 or argc > 2:
        print_usage()
        exit(1)

    root_dir: Path = Path.home() / ".config" / "vscodium"

    theme_dir: Path = root_dir / "themes" if argc == 1 else Path(argv[1]).resolve()

    package_json: dict = {
        "name": "elysian-color-themes",
        "displayName": "Elysian Themes",
        "description": "Color themes for my dotfiles",
        "publisher": "quisiou",
        "version": "0.1.0",
        "private": True,
        "engines": {
            "vscode": "^1.50.0"
        },
        "categories": [
            "Themes"
        ],
        "contributes": {
            "themes": get_themes_info(theme_dir, root_dir)
        },
        "repository": {
            "type": "git",
            "url": "https://github.com/quisiou/Dotfiles.git",
            "directory": "vscodium"
        }
    }

    with open(root_dir / "package.json", "w") as f:
        f.write(json.dumps(package_json, indent=4) + '\n')

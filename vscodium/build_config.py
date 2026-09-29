# vscodium/build_config.py


from os import mkdir
from pathlib import Path
from sys import argv
import json


def print_usage():
    print("Usage:")
    print("\tpython3 build_config.py [--overwrite]")


def build_settings(config_dir: Path):
    with open(config_dir / "settings.json", 'w') as f:
        f.write(json.dumps(
            {
                "workbench.sideBar.location": "right",
                "window.menuBarVisibility": "compact",
                "workbench.activityBar.location": "top",
                "window.commandCenter": False,
                "workbench.startupEditor": "none",
                "workbench.colorTheme": "Tokyo Carbon",
                "editor.fontSize": 18,
                "editor.fontFamily": "JetBrainsMono Nerd Font, 'FiraCode Nerd Font'",
                "editor.fontWeight": "500",
                "editor.fontLigatures": True,
                "explorer.confirmDelete": False,
                "editor.inlayHints.enabled": "offUnlessPressed",
                "git.openRepositoryInParentFolders": "never",
                "jupyter.askForKernelRestart": False,
                "explorer.confirmDragAndDrop": False,
                "clangd.path": "clangd",
                "clangd.arguments": [
                    "--header-insertion=never"
                ],
                "python.createEnvironment.trigger": "off",
                "python.analysis.diagnosticSeverityOverrides": {
                    "reportOptionalMemberAccess": "none",
                    "reportOptionalCall": "none",
                    "reportOptionalSubscript": "none",
                    "reportAssignmentType": "none",
                    "reportArgumentType": "none"
                },
                "qt-qml.qmlls.customExePath": "qmlls",
                "qt-qml.qmlls.useQmlImportPathEnvVar": True,
                "workbench.editorAssociations": {
                    "{git,gitlens,copilot,git-graph,git-graph-3}:/**/*.qrc": "default",
                    "*.qrc": "qt-core.qrcEditor",
                    "*.svg": "default"
                },
                "qt-qml.doNotAskForQmllsDownload": True
            },
            indent=4
        ))


def build_keybindings(config_dir: Path):
    with open(config_dir / "keybindings.json", 'w') as f:
        f.write(json.dumps(
            [
                {
                    "key": "ctrl+alt+z",
                    "command": "workbench.action.terminal.newWithProfile",
                    "args": { "profileName": "zsh" }
                }
            ],
            indent=4
        ))


def build_snippets(config_dir: Path):
    pass


if __name__ == "__main__":
    overwrite: bool = "--overwrite" in argv[1:]
    if len(argv) > 2 or (len(argv) == 2 and not overwrite):
        print_usage()
        exit(1)

    config_dir: Path = Path.home() / ".config" / "VSCodium" / "User"
    config_dir.mkdir(exist_ok=True, parents=True)

    for name, build in (("settings.json", build_settings), ("keybindings.json", build_keybindings)):
        # is_symlink(): a leftover dangling symlink from the old layout counts as existing
        if overwrite or not (config_dir / name).exists():
            if (config_dir / name).is_symlink():
                (config_dir / name).unlink()
            build(config_dir)
            print(f"    created    {config_dir / name}")
        else:
            print(f"    skipped    {config_dir / name}: file already exists")

    if not Path(config_dir, "snippets").exists():
        Path(config_dir, "snippets").mkdir()
        build_snippets(config_dir)
        print(f"    created    {config_dir / 'snippets'}/")
    else:
        print(f"    skipped    {config_dir / 'snippets'}/: file already exists")

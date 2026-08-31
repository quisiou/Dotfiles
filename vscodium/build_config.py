# VSCodium/build_config.py


from os import mkdir
from pathlib import Path
from sys import argv
import json


def print_usage():
    print("Usage:")
    print("\tpython3 build_config.py")


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
    argc: int = len(argv)
    if argc < 1 or argc > 2:
        print_usage()
        exit(1)

    config_dir: Path = Path(__file__).resolve().parent / "config"
    config_dir.mkdir(exist_ok=True, parents=True)

    if not Path(config_dir, "settings.json").exists():
        build_settings(config_dir)

    if not Path(config_dir, "keybindings.json").exists():
        build_keybindings(config_dir)

    if not Path(config_dir, "snippets").exists():
        Path(config_dir, "snippets").mkdir()
        build_snippets(config_dir)

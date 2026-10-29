# <module>

One-line description of what this module configures.


## Functionality
- What it sets up (config files, themes, scripts, daemons).
- Where it ends up (e.g. `~/.config/<module>/`, `$ELYSIAN_DOTS_HOME/<dir>`).
- How other modules use it, and which modules depend on it.


## Dependencies
### Required

| Tool | Provides | Used by |
|------|----------|---------|
| `tool` | `binary` | where it is called (file or feature) |


### System utilities
Basic tools expected on any system (`sh`, `awk`, `find`, ...).


### Optional

| Tool | Enables |
|------|---------|
| `tool` | feature that only works with it |


### Fonts / themes / plugins
- Fonts, icon themes, cursor themes, plugins, or other non-binary assets.


### Other modules
- `<module>`: why this one is needed.


## Setup
### Script (`setup.sh`)
```sh
./setup.sh [flags]
```


| Flag | Effect |
|------|--------|
| `--<module>-f` | Recreate the destination directory |
| `--<module>-o` | Replace existing targets and caches |


Requires: `ELYSIAN_DOTS_HOME` (see the [zsh](../zsh/README.md) module).


### NixOS flake
```nix
programs.dotfiles.modules.<module> = {
    enable = true;
    # options below
};
```


| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `package` | package | `pkgs.<module>` | Package to use |
| `settings.<name>` | `type` | `null` | Description (and env var / config key it maps to) |


Packages installed (`nix/tools.nix`): `pkg1`, `pkg2`.


## Notes
- Assumptions and limitations (e.g. single monitor, hardcoded names).
- Behaviour that differs between `setup.sh` and the Nix setup.


## TODO
- [ ] Pending improvements
- [ ] Known issues or bugs found


## Install
Per-distro install commands.


| Distro | Command |
|--------|---------|
| Arch | |
| Debian/Ubuntu | |
| Fedora | |
| Nix | |

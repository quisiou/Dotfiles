# extract-to.yazi

A [Yazi](https://github.com/sxyazi/yazi) plugin that extracts the hovered archive into a folder of your choice, using a popup input like Yazi's filter prompt.

- Empty input: extracts into `./<archive-name>/` (`foo.tar.gz` becomes `foo/`)
- Name provided: extracts into `./<name>/` instead
- Absolute paths (starting with `/`) are used as-is

Handles zip, rar, 7z, tar.gz, tar.xz, tar.bz2 and anything else 7-Zip supports.

## Requirements

- Yazi (tested on the version you use; update this line with `yazi --version`)
- [7-Zip](https://www.7-zip.org/) available as `7zz` (`7z` or `7za` also work if you edit the plugin)

## Installation

```sh
ya pkg add YOUR_USER/extract-to
```

Or manually:

```sh
git clone https://github.com/YOUR_USER/extract-to.yazi ~/.config/yazi/plugins/extract-to.yazi
```

## Usage

Check `~/.config/yazi/keymap.toml`:

```toml
[[mgr.prepend_keymap]]
on   = "<C-x>"
run  = "plugin extract-to"
desc = "Extract archive to named folder"
```

Hover an archive, press the key, type a destination name (or leave it empty), and press Enter. `Esc` cancels.

## Customization

The extraction command lives in the `extract` function at the top of `main.lua`. To use a different tool, such as `bsdtar` or `ouch`, replace that function.

## Notes

- Only the hovered file is processed, not a multi-selection.
- Existing files in the destination are overwritten (`-y`). Use `-aos` in `main.lua` to skip them instead.

## License

MIT, see [LICENSE](LICENSE).

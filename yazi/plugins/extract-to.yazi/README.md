[//]: # (yazi/plugins/extract-to.yazi/README.md)


# extract-to.yazi

A [Yazi](https://github.com/sxyazi/yazi) plugin that extracts the hovered archive into a folder of your choice, using a popup input like Yazi's filter prompt.

- Empty input: extracts into `./<archive-name>/` (`foo.tar.gz` becomes `foo/`)
- Name provided: extracts into `./<name>/` instead
- Absolute paths (starting with `/`) are used as-is

Tar archives (`.tar`, `.tar.gz`, `.tar.xz`, `.tar.bz2`, `.tar.zst`, `.tgz`, `.txz`, `.tbz2`, `.tbz`, `.tzst`) are extracted with `tar`. Everything else (zip, rar, 7z and anything else 7-Zip supports) is extracted with `7zz`.

## Requirements

- Yazi (tested on 26.9.1)
- `tar`, plus the matching decompressor for the formats you use (`gzip`, `xz`, `bzip2`, `zstd`)
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

Add to `~/.config/yazi/keymap.toml`:

```toml
[[mgr.prepend_keymap]]
on   = "<C-x>"
run  = "plugin extract-to"
desc = "Extract archive to named folder"
```

Hover an archive, press the key, type a destination name (or leave it empty), and press Enter. `Esc` cancels.

## Customization

The extraction commands live in the `extract` function at the top of `main.lua`. The `case` statement picks the tool by file extension:

- To handle another tar variant, add its extension to the first branch.
- To use a different tool for the non-tar formats, such as `bsdtar` or `ouch`, edit the second branch.

## Notes

- Only the hovered file is processed, not a multi-selection.
- Existing files in the destination are overwritten by default (`tar` does this natively, `7zz` via `-y`). To keep existing files instead, use `tar -xkf` for tar archives, and `-aos` in place of `-y` for `7zz`.
- Tar archives are detected by extension, so a misnamed file (a `.tar.gz` that is really a zip) will fail. Rename it and try again.

## License

MIT, see [LICENSE](LICENSE).

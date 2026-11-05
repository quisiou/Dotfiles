[//]: # (yazi/plugins/compress-to.yazi/README.md)


# compress-to.yazi

A [Yazi](https://github.com/sxyazi/yazi) plugin that compresses the selected files (or the hovered one) into an archive, using a popup input like Yazi's filter prompt. The format is picked from the extension you type.

- Empty input, one item: archive is named after the item (`foo/` becomes `foo.zip`)
- Empty input, several items: archive is named after the current folder
- No recognized extension: `.zip` is appended
- Items are stored with paths relative to the current folder, so the archive doesn't embed full paths
- Existing archives are never overwritten, and the plugin refuses with an error instead

## Supported formats

| Extension                | Tool   |
|--------------------------|--------|
| `.zip`                   | `7zz`  |
| `.7z`                    | `7zz`  |
| `.tar`                   | `tar`  |
| `.tar.gz`, `.tgz`        | `tar`  |
| `.tar.xz`, `.txz`        | `tar`  |
| `.tar.bz2`, `.tbz2`      | `tar`  |

## Requirements

- Yazi (tested on 26.9.1)
- `tar`, plus the matching compressor for the formats you use (`gzip`, `xz`, `bzip2`)
- [7-Zip](https://www.7-zip.org/) available as `7zz` (`7z` or `7za` also work if you edit the plugin)

## Installation

```sh
ya pkg add YOUR_USER/compress-to
```

Or manually:

```sh
git clone https://github.com/YOUR_USER/compress-to.yazi ~/.config/yazi/plugins/compress-to.yazi
```

## Usage

Add to `~/.config/yazi/keymap.toml`:

```toml
[[mgr.prepend_keymap]]
on   = "<A-c>"
run  = "plugin compress-to"
desc = "Compress selection to archive"
```

Select one or more items (or just hover one), press the key, type an archive name such as `backup.tar.gz` (or leave it empty), and press Enter. `Esc` cancels.

## Customization

The compression commands live in the `compress` function at the top of `main.lua`. The `case` statement picks the tool by the output extension:

- To add a tar variant, add a branch with the right `tar` flag (for example `*.tar.zst) tar --zstd -cf "$out" -- "$@" ;;`) and add its extension to the `known` list so it isn't turned into a `.zip`.
- To use a different tool for zip/7z, such as `bsdtar` or `ouch`, edit the last two branches.

## Notes

- If the command fails, any partially written archive is removed.
- Selected items outside the current folder are stored with their absolute paths.
- File names starting with `-` are handled safely (`--` is passed before the item list).

## License

MIT, see [LICENSE](LICENSE).

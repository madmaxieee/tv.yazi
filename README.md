# yazi-tv

This is a plugin for the [yazi](https://github.com/sxyazi/yazi) file manager that integrates with the [tv](https://github.com/alexpasmantier/television) command-line tool.

## Features

This plugin allows you to use `tv` as a file picker within yazi. It supports two modes:

- **files**: The selected file is revealed in yazi.
- **text**: Search file by content and open the file in `nvim` at the specific line.

## Requirements

- [tv](https://github.com/alexpasmantier/television)

## Setup

```toml
[[mgr.prepend_keymap]]
on = ["f", "w"]
run = "plugin tv -- text"
desc = "search file by content"

[[mgr.prepend_keymap]]
on = ["f", "f"]
run = "plugin tv -- files"
desc = "find file by filename"
```

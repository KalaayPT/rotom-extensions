# nvim-rotom

Neovim plugin for the Rotom scripting language.

## Requirements

- Neovim >= 0.10
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- `rotom-lsp` binary on your `$PATH`

## Installation

### lazy.nvim

```lua
{
  "KalaayPT/rotom-lang",
  ft = "rotom",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("rotom").setup()
  end,
}
```

After installing, run `:TSInstall rotom` to install the parser.

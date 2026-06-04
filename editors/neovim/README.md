# nvim-rotom

Neovim plugin for the [Rotom](https://github.com/KalaayPT/rotom) scripting language.

## Requirements

- Neovim >= 0.11 (built-in `vim.lsp.config`) or 0.10 with [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- `rotom-lsp` on `$PATH`, or a workspace `target/{debug,release}/rotom-lsp` build
- [tree-sitter CLI](https://tree-sitter.github.io/tree-sitter/creating-parsers#installing-the-cli) (only when installing the parser from source)

## Installation

### lazy.nvim

```lua
{
  "KalaayPT/rotom-extensions",
  name = "rotom.nvim",
  lazy = false,
  config = function(plugin)
    vim.opt.rtp:prepend(plugin.dir .. "/editors/neovim")
    require("rotom").setup()
  end,
}
```

Do **not** use `ft = { "rotom" }` — the plugin registers that filetype itself, so lazy would never load.

To lazy-load by filename instead:

```lua
{
  "KalaayPT/rotom-extensions",
  name = "rotom.nvim",
  event = { "BufReadPost *.rotom", "BufReadPost */textArchives/*.json", "BufReadPost */res/text/*.json" },
  config = function(plugin)
    vim.opt.rtp:prepend(plugin.dir .. "/editors/neovim")
    require("rotom").setup()
  end,
}
```

For local development, replace the repo string with `dir = vim.fn.expand("~/dev/rotom-extensions")`.

### vim-plug

```vim
Plug 'KalaayPT/rotom-extensions', { 'rtp': 'editors/neovim' }
```

### Manual

Add `editors/neovim` to your `'runtimepath'` and run `require("rotom").setup()`.

If commands are still **white**, delete the cached parser and reopen a `.rotom` buffer:

```bash
rm -rf ~/.local/share/nvim/rotom/tree-sitter-rotom
```

If you use **nvim-treesitter**, disable its highlight for Rotom so it does not override this plugin:

```lua
require("nvim-treesitter.configs").setup({
  highlight = {
    enable = true,
    disable = { "rotom" },
  },
})
```

## Configuration

```lua
require("rotom").setup({
  -- Path to rotom-lsp (default: $PATH, then workspace target/debug|release)
  lsp_path = nil,

  -- Extra vim.lsp.Config / lspconfig options
  lsp = {
    -- on_attach = function(client, bufnr) end,
  },

  -- Clone and build tree-sitter-rotom when the parser is missing (default: true)
  install_parser = true,

  -- Map **/textArchives/** and **/res/text/** JSON to rotom_text_archive (default: true)
  archive_json = true,
})
```

Set `lsp = false` to skip the language server. Set `treesitter = false` to skip tree-sitter setup.

## Features

| Feature | Support |
|---------|---------|
| Diagnostics | Yes (via `rotom-lsp`) |
| Completion / hover / signature help | Yes |
| Go to definition | Yes |
| Inlay hints | Yes (Neovim built-in) |
| CodeLens reference counts | Yes — run with `grx` or `:lua vim.lsp.codelens.run()` |
| Text archive JSON (`textArchives/`, `res/text/`) | Yes — separate `rotom_text_archive` filetype |

CodeLens clicks use Neovim's `editor.action.showReferences` handler (quickfix list + location preview), matching the VS Code extension behavior.

## CodeLens

Reference lenses are enabled on LSP attach. On the current line:

- Default mapping: `grx`
- Command: `:lua vim.lsp.codelens.run()`

## LSP binary resolution

1. `lsp_path` option (if the file exists)
2. `target/debug/rotom-lsp` or `target/release/rotom-lsp` under a `rotom.toml` / `.git` workspace root
3. `rotom-lsp` on `$PATH`

Build from the compiler repo:

```sh
cargo build -p rotom-lsp
```

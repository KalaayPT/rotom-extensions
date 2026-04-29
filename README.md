# Rotom Language Tooling

Centralized editor support for the [Rotom](https://github.com/KalaayPT/rotom) scripting language — a high-level compiler toolchain for Pokémon Generation 4 (Diamond/Pearl/Platinum/HeartGold/SoulSilver) field scripts.

## What's in this repo

| Package | Purpose | Editors Served |
|---------|---------|----------------|
| `tree-sitter-rotom/` | Canonical grammar + queries | Zed, Neovim, GitHub, any tree-sitter consumer |
| `rotom-lsp/` | Language Server Protocol implementation | VS Code, Zed, Neovim, Emacs, Helix, etc. |
| `editors/vscode/` | VS Code extension (client + TextMate grammar) | VS Code |
| `editors/zed/` | Zed extension (grammar + LSP launcher) | Zed |
| `editors/neovim/` | Neovim Lua plugin (treesitter + LSP setup) | Neovim |

## Quick Start

### Prerequisites

- Rust toolchain (for `rotom-lsp`)
- Node.js + npm (for tree-sitter grammar development and VS Code extension)
- Tree-sitter CLI: `cargo install tree-sitter-cli --locked`

### Building

```bash
# Build the tree-sitter grammar
cd tree-sitter-rotom
tree-sitter generate
tree-sitter test

# Build the LSP
cd ../rotom-lsp
cargo build --release

# Build the VS Code extension
cd ../editors/vscode
npm install
npm run compile

# Build the Zed extension
cd ../zed
cargo build --release
```

### Installing

**Neovim (lazy.nvim):**
```lua
{
  "KalaayPT/rotom-lang",
  ft = "rotom",
  config = function()
    require("rotom").setup()
  end,
}
```

**VS Code:**
Install from the marketplace (or run `code --install-extension rotom-*.vsix`).

**Zed:**
Install from the Zed extensions panel (search "Rotom").

## Contributing

See [`PLAN.md`](./PLAN.md) for the architecture roadmap and required modifications
to the upstream `rotom` compiler.

## License

Same as the upstream `rotom` project (see LICENSE).

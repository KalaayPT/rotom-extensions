# Editor Integration Guide

This document explains how each editor connects to the centralized Rotom
language tooling.

## Architecture Overview

```
+----------------+     +-------------------+     +------------------+
|    Editor      |<--->|   rotom-lsp       |<--->|   rotom lib      |
|  (VSCode/Zed/  | LSP |  (tower-lsp)      |     | (parser/analyzer/|
|   Neovim/...)  |     |                   |     |  database)       |
+----------------+     +-------------------+     +------------------+
         |
         | registers / consumes
         v
+-------------------+
| tree-sitter-rotom |
|  (grammar +       |
|   queries)        |
+-------------------+
```

## VS Code

VS Code uses a **hybrid** approach:
1. **TextMate grammar** (`syntaxes/rotom.tmLanguage.json`) provides baseline
   syntax highlighting immediately on file open.
2. **Language Client** (`src/extension.ts`) spawns `rotom-lsp` as a stdio
   subprocess.
3. The LSP provides diagnostics, completions, hover, go-to-definition, and
   (optionally) semantic tokens that augment the TextMate highlighting.

## Zed

Zed is **tree-sitter native**:
1. The extension registers `tree-sitter-rotom` in `extension.toml`.
2. Zed compiles the grammar and loads `highlights.scm`, `brackets.scm`,
   `indents.scm`, `outline.scm`, etc. automatically.
3. The Rust extension (`src/lib.rs`) returns the `rotom-lsp` command; Zed
   manages the LSP lifecycle.

## Neovim

Neovim uses **nvim-treesitter** + **built-in LSP**:
1. The Lua plugin registers the tree-sitter parser with
   `nvim-treesitter.parsers`.
2. The plugin configures `lspconfig` to start `rotom-lsp` for `.rotom` files.
3. Users install the parser via `:TSInstall rotom`.

## Helix / Kakoune / Emacs

Any editor that supports:
- **tree-sitter grammars** can use `tree-sitter-rotom` for highlighting.
- **LSP clients** can connect to `rotom-lsp` for intelligence.

No custom extension code is required for these editors; just configure the
grammar path and LSP command.

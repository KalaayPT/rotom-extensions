# LSP Features

| Capability | Status | Notes |
|-----------|--------|-------|
| `initialize` / `shutdown` | ✅ | |
| `textDocument/didOpen/didChange/didClose` | ✅ | Incremental sync |
| `textDocument/publishDiagnostics` | ✅ | Debounced 300ms |
| `textDocument/definition` | ✅ | Scripts, labels, aliases, actions |
| `textDocument/documentSymbol` | ✅ | Grouped: Scripts / Aliases / Labels / Actions |
| `textDocument/completion` | ✅ | Commands, constants, local symbols |
| `textDocument/hover` | ✅ | Command docs, legacy aliases, constant values |
| `textDocument/signatureHelp` | ✅ | Command arg hints |
| `textDocument/inlayHint` | ✅ | Command parameter names |
| `textDocument/codeLens` (scripts) | ✅ | Label/function/action reference counts |
| `textDocument/codeLens` (text archives) | ✅ | Per-message script reference counts |
| `workspace/symbol` | ❌ | |
| `textDocument/formatting` | ❌ | |
| `textDocument/semanticTokens` | ❌ | |

## Editor Notes

See each editor's README for editor-specific setup:

- **VS Code:** [editors/vscode/](../editors/vscode/)
- **Neovim:** [editors/neovim/](../editors/neovim/)
- **Zed:** [KalaayPT/rotom-zed](https://github.com/KalaayPT/rotom-zed)

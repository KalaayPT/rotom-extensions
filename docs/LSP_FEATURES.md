# LSP Features

| Capability | Status | Notes |
|-----------|--------|-------|
| `initialize` / `shutdown` | ✅ | |
| `textDocument/didOpen/didChange/didClose` | ✅ | Incremental sync |
| `textDocument/publishDiagnostics` | ✅ | Debounced 300ms |
| `textDocument/definition` | ✅ | Scripts, labels, aliases, actions |
| `textDocument/documentSymbol` | ✅ | Grouped: Scripts / Labels / Actions |
| `textDocument/completion` | ✅ | Commands, constants, local symbols |
| `textDocument/hover` | ✅ | Command docs, legacy aliases, constant values |
| `textDocument/signatureHelp` | ✅ | Command arg hints |
| `textDocument/inlayHint` | ✅ | Command parameter names |
| `workspace/symbol` | ❌ | |
| `textDocument/formatting` | ❌ | |
| `textDocument/semanticTokens` | 🔄 | |

## Editor Notes

**VS Code:** All features work. CodeLens clicks open the reference peek view via `rotom.showReferences`.

**Zed:** Diagnostics, completions, hover, go-to-definition, and inlay hints and Codelens work. Signature help may not trigger automatically.

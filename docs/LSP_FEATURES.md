# LSP Features Matrix

This document tracks which LSP capabilities `rotom-lsp` implements and their
status.

## Legend

- ✅ Implemented
- 🚧 In Progress
- ❌ Not Started
- 🔄 Planned

## Capabilities

| Capability | Status | Notes |
|-----------|--------|-------|
| **Lifecycle** |
| `initialize` | ✅ | Server capabilities advertised |
| `initialized` | ✅ | Log message |
| `shutdown` | ✅ | No-op |
| `textDocument/didOpen` | ✅ | Document cached |
| `textDocument/didChange` | ✅ | Incremental sync |
| `textDocument/didClose` | ✅ | Document removed |
| **Diagnostics** |
| `textDocument/publishDiagnostics` | 🚧 | Needs error-tolerant parser from rotom |
| **Navigation** |
| `textDocument/definition` | 🚧 | Alias -> alias def, Jump -> label def |
| `textDocument/documentSymbol` | 🚧 | Functions, actions, labels, aliases |
| `workspace/symbol` | ❌ | Needs workspace indexing |
| **Completions** |
| `textDocument/completion` | 🚧 | Commands, aliases, constants, labels |
| `completionItem/resolve` | ❌ | Documentation on demand |
| **Hover** |
| `textDocument/hover` | 🚧 | Command docs from DB, alias values |
| **Signature Help** |
| `textDocument/signatureHelp` | ❌ | Command arg hints |
| **Formatting** |
| `textDocument/formatting` | ❌ | Auto-format Rotom source |
| **Semantic Highlighting** |
| `textDocument/semanticTokens` | 🔄 | Future: fine-grained token types |

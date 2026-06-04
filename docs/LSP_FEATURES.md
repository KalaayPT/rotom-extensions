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

**VS Code:** All features work. CodeLens clicks open the reference peek view via `rotom.showReferences`.
Archive JSON under `**/textArchives/**` and `**/res/text/**` is routed to `rotom-lsp` (not only `.rotom`).

**Neovim:** All features work via `editors/neovim`. CodeLens uses `editor.action.showReferences`
(quickfix + location preview). Archive JSON under `textArchives/` and `res/text/` uses the
`rotom_text_archive` filetype so `jsonls` does not take over. See `editors/neovim/README.md`.

**Zed:** Archive files use a separate language, **Rotom Text Archive** (tree-sitter JSON grammar +
`rotom-lsp`). Normal `package.json` etc. stay built-in **JSON**. CodeLens reference counts are shown
and use Zed's built-in references UI when clicked.

To enable archive CodeLens in Zed, opt into the archive file association in project or user settings:

```json
"file_types": {
  "Rotom Text Archive": ["**/textArchives/**", "**/res/text/**"]
}
```

**Important:** Do not add `"JSON"` to the extension's `language_servers` in `extension.toml` and
do not set `"languages": { "JSON": { "language_servers": ["rotom-lsp"] } }` in settings — that
breaks Zed's built-in JSON (`no such grammar json` in the log).

After changing the extension, run **zed: reload extensions**, then **restart Zed** if plain JSON
files still fail to open. Reopen archive JSON — status bar should say **Rotom Text Archive**.

**Dev extension install:** If install fails with `failed to compile grammar 'rotom'`, delete
`editors/zed/grammars/` in the extension tree. A leftover local grammar clone blocks the GitHub fetch.

Diagnostics, completions, hover, go-to-definition, inlay hints, and CodeLens work on `.rotom`.
Archive CodeLens requires **Rotom Text Archive** via `file_types` above; see `editors/zed/README.md`.
Signature help may not trigger automatically.

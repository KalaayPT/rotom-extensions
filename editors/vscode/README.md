# Rotom VS Code Extension

## Setup

1. Build the LSP: `cargo build -p rotom-lsp` in the `rotom` repo.
2. Install deps: `npm install` in this directory.
3. Open this folder in VS Code and press `F5` to launch the Extension Development Host.

## Configuration

```json
{ "rotom.lsp.path": "/path/to/rotom-lsp" }
```

If unset, searches the extension `bin/` directory, workspace `target/` builds, then `$PATH`.

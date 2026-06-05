# Rotoscript Support

VS Code extension for the [Rotom](https://github.com/KalaayPT/rotom) scripting language.

Install it from:

- [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=Kalaay.rotom-vscode)
- [Open VSX](https://open-vsx.org/extension/Kalaay/rotom-vscode)

## Requirements

The compiler and language server live in the main [Rotom repository](https://github.com/KalaayPT/rotom). Install or build `rotom-lsp` from that repo and make sure it is available on `$PATH`; that is the expected setup for normal use.

For local development from the Rotom repo:

```sh
cargo build -p rotom-lsp
```

The extension looks for `rotom-lsp` in this order:

1. `rotom.lsp.path`, if configured
2. Bundled extension `bin/` directory
3. Workspace `target/debug` or `target/release` builds
4. `$PATH`

## Configuration

Most users should not need any VS Code settings. Use `rotom.lsp.path` only to override language server resolution for local development or troubleshooting:

```json
{ "rotom.lsp.path": "/path/to/rotom-lsp" }
```

## Extension Development

```sh
npm install
npm run compile
```

Open this folder in VS Code and press `F5` to launch the Extension Development Host.

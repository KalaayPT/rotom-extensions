# AGENTS.md

Project-specific rules for agents working on Rotom language tooling.

## Repository Map

```
rotom/                          # Compiler + LSP workspace
├── src/                        # rotom compiler library + CLI
│   ├── compiler/
│   │   ├── token.rs            # TokenType enum
│   │   ├── lexer.rs            # Lexer
│   │   ├── parser.rs           # Parser with error-tolerant mode (new_fallible)
│   │   ├── ast.rs              # StatementKind, ExpressionKind
│   │   ├── analysis.rs         # Semantic analyzer
│   │   └── sourcemap.rs        # byte ↔ LSP position conversion
│   ├── database.rs             # ConstantDb, DatabaseV2, apply_directives bridge
│   └── lib.rs                  # Public API: compile(), compile_to_bytes(), compile_ast()
├── rotom-lsp/src/
│   ├── server.rs               # LSP handlers + file_local_constants
│   ├── diagnostics.rs          # Real-time error squiggles (debounced 300ms)
│   ├── completions.rs          # Context-aware autocomplete
│   ├── hover.rs                # Command docs, constant values
│   └── code_lens.rs            # Reference counts

tree-sitter-rotom/              # Standalone Tree-sitter grammar
├── grammar.js
├── queries/highlights.scm
└── src/                        # Generated parser C code (committed)

rotom-extensions/               # Editor integrations (thin adapters)
├── editors/vscode/             # VS Code extension
│   └── src/extension.ts        # Spawns rotom-lsp, handles CodeLens clicks
└── editors/zed/                # Zed extension
    ├── extension.toml          # Grammar + LSP registration
    └── src/lib.rs              # WASM extension spawning rotom-lsp

uxie/                           # External dependency: C constant resolution
└── src/c_parser/symbol_table.rs # SymbolTable, load_c_directives_with_handler()
```

## Project Philosophy

- **One grammar, one LSP server, thin editor adapters**
- **Parse once, reuse the AST** — never re-parse for constants or compilation
- **Uxie handles C constant evaluation** — never reimplement expression parsing, include resolution, or define evaluation in Rotom
- **Direct bridging** — AST nodes → Uxie structs. No synthetic source text.

## Preprocessor / Directive Pipeline

`#include` and `#define` are first-class tokens and AST nodes.

- **Lexer:** `#include` → `TokenType::Include`, `#define` → `TokenType::Define`
- **Parser:** `parse_top_level_stmt` matches `Include` and `Define` tokens → `StatementKind::Include` / `StatementKind::Define`
- **Bridge (`ConstantDb::apply_directives`):** builds `uxie::CInclude`/`uxie::CDefine` from AST, calls `SymbolTable::load_c_directives_with_handler()` — Uxie handles all evaluation
- `.rotom` files: parse ONCE → extract directives from AST → `apply_directives` → `compile_ast` with SAME AST
- The old `preprocessor.rs` module is deleted. Do not recreate it.

## Editor Extensions

**VS Code:** LSP sends `editor.action.showReferences` in CodeLens. The VS Code extension rewrites it to `rotom.showReferences`, which converts JSON args to VS Code `Uri`/`Position`/`Location` instances and calls the real command. Run `npm run compile` after TypeScript changes.

**Zed:** Uses `worktree.which("rotom-lsp")` to resolve the binary. Grammar loaded from GitHub. CodeLens clicks are display-only — Zed does not support custom LSP command handlers.

**Both must work:** never break one editor to fix the other.

## Code Style Rules

- Don't add helper methods called exactly once — inline them.
- Don't add `_with_options` variants — consolidate to minimal API surface.
- Don't reimplement Uxie logic in Rotom.
- Don't create synthetic C source strings when the AST is already available.
- Don't add comments unless asked.
- Match existing code style.
- Delete dead code aggressively.
- Run clippy on touched files. Zero new warnings.
- Don't commit unless asked.

## Testing & Verification

```
cargo test -p rotom --lib -- --test-threads=1
cargo clippy -p rotom -p rotom-lsp
cargo build -p rotom-lsp
cargo build --target wasm32-wasip1          # in editors/zed
npm run compile                              # in editors/vscode
tree-sitter generate && tree-sitter build   # in tree-sitter-rotom
```

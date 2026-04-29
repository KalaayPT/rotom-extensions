# Rotom Language Tooling Project

> Centralized editor tooling, LSP, and grammars for the Rotom scripting language.

## Repository Structure

```
rotom-lang/
├── PLAN.md                          # This document — master architecture plan
├── README.md                        # Quick start for contributors/users
├── tree-sitter-rotom/               # Universal Tree-sitter grammar
│   ├── grammar.js                   # Tree-sitter grammar definition
│   ├── queries/
│   │   ├── highlights.scm           # Syntax highlighting queries
│   │   ├── brackets.scm             # Bracket matching
│   │   ├── indents.scm              # Auto-indentation rules
│   │   ├── outline.scm              # Document symbol outline
│   │   ├── textobjects.scm          # Text objects (vim-like)
│   │   ├── injections.scm           # Language injections (none yet)
│   │   └── locals.scm               # Local variable scope queries
│   ├── package.json                 # npm manifest for tree-sitter
│   ├── Cargo.toml                   # Rust bindings (for rotom-lsp)
│   └── bindings/
│       └── rust/lib.rs              # Rust FFI bindings
├── rotom-lsp/                       # Language Server Protocol implementation
│   ├── Cargo.toml
│   └── src/
│       ├── main.rs                  # Binary entry point
│       ├── server.rs                # LSP server (tower-lsp)
│       ├── diagnostics.rs           # Real-time diagnostic engine
│       ├── completions.rs           # Auto-completion provider
│       ├── hover.rs                 # Hover info / docs provider
│       ├── symbols.rs               # Document/workspace symbols
│       ├── goto.rs                  # Go-to-definition
│       ├── formatting.rs            # Document formatting (future)
│       └── document.rs              # Document cache & incremental sync
├── editors/
│   ├── vscode/                      # VS Code extension
│   │   ├── package.json
│   │   ├── src/extension.ts         # LSP client launcher
│   │   ├── syntaxes/rotom.tmLanguage.json  # TextMate grammar (derived)
│   │   └── language-configuration.json
│   ├── zed/                         # Zed extension
│   │   ├── extension.toml
│   │   ├── Cargo.toml
│   │   ├── src/lib.rs
│   │   └── languages/rotom/
│   │       ├── config.toml
│   │       └── highlights.scm       # (symlink to tree-sitter queries)
│   └── neovim/                      # Neovim plugin
│       ├── lua/rotom/
│       │   ├── init.lua             # Plugin setup
│       │   ├── treesitter.lua       # Tree-sitter config
│       │   └── lsp.lua              # LSP client config
│       └── README.md
└── docs/
    ├── INTEGRATION.md               # How editors integrate each component
    ├── GRAMMAR.md                   # Rotom grammar reference
    ├── LSP_FEATURES.md              # Supported LSP capabilities matrix
    └── ROTOM_MODIFICATIONS.md       # Required changes to rotom compiler
```

---

## Philosophy: One Grammar, One Server, Thin Adapters

All editor support is built on two centralized artifacts:

1. **Tree-sitter grammar** (`tree-sitter-rotom`) — the canonical parser for syntax
   highlighting, structural editing, and AST-based queries in every editor.
2. **LSP binary** (`rotom-lsp`) — the canonical source of language intelligence
   (diagnostics, completions, go-to-definition, hover, etc.).

Editor integrations are **thin adapters** that:
- Register the tree-sitter grammar (Zed, Neovim, some VS Code setups)
- Spawn and communicate with `rotom-lsp` via stdio (all editors)
- Ship a derived TextMate grammar for VS Code fallback highlighting

---

## Component Breakdown

### 1. Tree-sitter Grammar (`tree-sitter-rotom`)

**Why tree-sitter?**
- It is the parsing engine for Zed, Neovim (via nvim-treesitter), GitHub, and many
  other tools.
- Once we have a grammar, we get syntax highlighting, indentation, bracket
  matching, outline views, and text objects in multiple editors for free.
- The C-based parser is fast and incremental.

**Grammar scope:**
- Must accurately parse the full Rotom surface syntax per `rotoscript_spec.md`:
  - Comments (`//`, `/* */`)
  - Identifiers, numbers (decimal, hex), labels
  - Keywords: `function`, `action`, `alias`, `if`/`then`/`else`/`endif`,
    `while`/`do`/`endwhile`, `match`/`with`/`case`/`endmatch`, `break`,
    `Jump`, `End`, `Return`, `EndMovement`, `and`, `or`, `not`, `true`, `false`
  - Operators: `==`, `!=`, `<=`, `>=`, `<`, `>`, `&&`, `||`, `!`, `+`, `-`, `*`
  - Punctuation: `(`, `)`, `,`, `:`, `.`, `#`, `=`
  - Function headers: `function Name #N:`
  - Stacked headers: `function A #1:` followed by `function B #2:`
  - Top-level labels: `LabelName:`
  - Inline labels: `.local_label:`
  - Action blocks: `action Name ... EndMovement`
  - Command invocations: `CommandName arg1, arg2, ...`
  - Expressions: prefix, infix, call
  - Alias declarations: `alias Value as Name`
  - Preprocessor directives: `#include`, `#define` (for parity with decomp headers)

**Query files to provide:**
- `highlights.scm` — maps AST nodes to highlight captures (`@keyword`, `@function`,
  `@number`, `@comment`, etc.)
- `brackets.scm` — pairs like `if/endif`, `while/endwhile`, `match/endmatch`, `(`/`)`
- `indents.scm` — indent after `function`, `action`, `if`, `while`, `match`, `case`,
  `then`, `else`; dedent on `endif`, `endwhile`, `endmatch`, `EndMovement`, `End`, `Return`
- `outline.scm` — expose `function`, `action`, and top-level `label` as document symbols
- `textobjects.scm` — `function.around`, `function.inside`, `comment.around`
- `locals.scm` — scope of inline labels, aliases, and variables (for locals highlighting)

**CI / publishing:**
- GitHub Actions to run `tree-sitter test` on PRs.
- Publish to npm (`tree-sitter-rotom`) so editors can consume it.
- Publish Rust crate (`tree-sitter-rotom`) for `rotom-lsp` to use directly.

---

### 2. Language Server (`rotom-lsp`)

**Why a separate LSP binary?**
- The main `rotom` crate is a compiler, not an interactive service.
- LSP needs incremental document sync, error-tolerant parsing, and fast response
  times — requirements that differ from batch compilation.

**Implementation:** Rust + [`tower-lsp`](https://crates.io/crates/tower-lsp).

**Architecture:**
```
main.rs
 └─> Server (tower-lsp)
      ├─> DocumentCache (incremental text sync)
      ├─> DiagnosticsEngine
      │    └─> links against rotom lib for lex + parse + analysis
      ├─> CompletionProvider
      │    └─> uses rotom DatabaseV2 + ConstantDb
      ├─> HoverProvider
      ├─> SymbolProvider
      └─> GotoProvider
```

**LSP capabilities (phased rollout):**

| Phase | Capability | Notes |
|-------|-----------|-------|
| 1 | `textDocumentSync` (incremental) | Required baseline |
| 1 | `textDocument/publishDiagnostics` | Real-time error reporting |
| 1 | `textDocument/completion` | Command names, aliases, constants, labels |
| 2 | `textDocument/hover` | Command docs from DB, alias values |
| 2 | `textDocument/definition` | Jump to alias def, label def, function def |
| 2 | `textDocument/documentSymbol` | Outline of functions, actions, labels |
| 2 | `workspace/symbol` | Project-wide symbol search |
| 3 | `textDocument/signatureHelp` | Command argument hints |
| 3 | `textDocument/rename` | Rename alias / label across file |
| 3 | `textDocument/formatting` | Auto-format Rotom source |
| Future | `textDocument/semanticTokens` | Fine-grained highlighting via LSP |

**Key design constraints:**
- Must be **error-tolerant**: incomplete code in the editor must still produce a
  useful AST for completions and diagnostics.
- Must convert **byte spans → LSP line/character positions** (UTF-16 as per LSP spec).
- Must load the **command database** (`database.json`) and **constants** from the
  workspace (respecting `rotom.toml` if present).
- Should reuse the `rotom` crate as a library for lexing, parsing, analysis, and
  database loading.

---

### 3. VS Code Extension (`editors/vscode`)

**Structure:**
- **Client**: TypeScript extension using `vscode-languageclient/node` to spawn
  `rotom-lsp`.
- **Grammar**: TextMate JSON (`syntaxes/rotom.tmLanguage.json`) derived from the
  tree-sitter grammar for out-of-the-box syntax highlighting without requiring
  a separate tree-sitter extension.
- **Configuration**: `language-configuration.json` for comment toggling, bracket
  matching, auto-indentation rules.

**Key files:**
- `package.json` — contributes `rotom` language, activates on `.rotom`, registers
  the language client.
- `src/extension.ts` — locates `rotom-lsp` binary (bundled or on `$PATH`), starts
  the client.

**Distribution:**
- Publish to VS Code Marketplace / Open VSX.
- Bundle the platform-appropriate `rotom-lsp` binary or download it on first
  activation.

---

### 4. Zed Extension (`editors/zed`)

**Structure:**
- Rust extension using Zed's extension API.
- Registers the tree-sitter grammar by pointing to `tree-sitter-rotom` (local or
  GitHub).
- Registers `rotom-lsp` as the language server for `.rotom` files.

**Key files:**
- `extension.toml` — metadata, grammar repo reference, language server config.
- `src/lib.rs` — implements `zed::Extension`, returns the `rotom-lsp` command.
- `languages/rotom/config.toml` — language metadata (extension, comment tokens,
  tab size).
- `languages/rotom/highlights.scm` — symlink or copy of tree-sitter queries.

**Distribution:**
- Publish via Zed's extension registry.

---

### 5. Neovim Plugin (`editors/neovim`)

**Structure:**
- Pure Lua plugin (no compiled components needed because Neovim uses external
  tree-sitter parsers and LSP clients).
- Provides a `setup()` function that:
  1. Registers `rotom` with `nvim-treesitter` (points to `tree-sitter-rotom`).
  2. Configures `vim.lsp.start` (or `lspconfig`) for `rotom-lsp`.
  3. Sets up filetype detection for `.rotom`.

**Key files:**
- `lua/rotom/init.lua` — main setup.
- `lua/rotom/treesitter.lua` — parser installation & query setup.
- `lua/rotom/lsp.lua` — LSP client configuration.

**Distribution:**
- LuaRock or lazy.nvim / packer.nvim via GitHub.

---

## Required Modifications to the `rotom` Compiler

To make `rotom-lsp` possible without reimplementing the world, the main `rotom`
crate (in `~/dev/rotom`) needs the following changes. These are **additive**
changes — they do not break existing CLI behavior.

### 1. Error-Tolerant Parser

**Problem:** The current parser (`Parser::parse_script_file`) fails fast on the
first unexpected token. In an editor, the user is constantly typing incomplete
code; we need partial ASTs.

**Needed:**
- A `parse_script_file_fallible` method (or a configuration flag on `Parser`)
  that recovers from parse errors by inserting `Error` nodes into the AST and
  continuing to parse the next statement / block.
- Recovery strategies:
  - Skip to next newline or keyword boundary on unexpected tokens.
  - Synchronize at `function`, `action`, `if`, `while`, `match`, `End`, `endif`,
    `endwhile`, `endmatch`, `EndMovement`.
- The resulting AST should contain `StatementKind::Error` or similar nodes that
  preserve as much valid structure as possible.

**Impact:** High. Needed for any real-time diagnostics and completions.

### 2. Line/Column Position Conversion

**Problem:** All spans in `rotom` are byte ranges (`Range<usize>`). LSP requires
line and character (UTF-16 code unit) positions.

**Needed:**
- A `SourceMap` or `Position` utility in `rotom` that can convert byte offsets
  to `(line, column)` and back, accounting for UTF-8 multi-byte characters.
- Function signature: `fn byte_offset_to_position(source: &str, offset: usize) -> (u32, u32)`
- This should probably live in `rotom::compiler::sourcemap` or similar.

**Impact:** High. Required for all LSP features.

### 3. Expose Lexer as Public API

**Problem:** `Lexer` is public (`pub mod lexer`), but not easily usable for
incremental / partial tokenization.

**Needed:**
- Ensure `Lexer::new(source)` and `lexer.next_token()` are stable public APIs.
- Optionally, expose `tokenize()` which returns all tokens.
- The LSP may want raw tokens for certain completions or semantic highlighting.

**Impact:** Low. Mostly already public.

### 4. Expose Symbol Table & Scope Information

**Problem:** `Analyzer` builds a symbol table (`analyzer.symbols`), but the
structure and accessors are not public enough for an LSP to query definitions,
references, or completions.

**Needed:**
- Make the symbol table type public with query methods:
  - `fn resolve_alias(&self, name: &str) -> Option<&AliasInfo>`
  - `fn function_by_name(&self, name: &str) -> Option<&FunctionInfo>`
  - `fn label_by_name(&self, name: &str) -> Option<&LabelInfo>`
  - `fn all_commands(&self) -> &[CommandInfo]` (for completions)
  - `fn constants_in_scope(&self) -> &[ConstantInfo]`
- Include span information in every symbol entry so the LSP can map back to
  source locations.
- Consider adding scope information for inline labels (which are local to a
  function).

**Impact:** High. Needed for go-to-definition, document symbols, and completions.

### 5. Expose Database Query APIs

**Problem:** `DatabaseV2` and `ConstantDb` are public, but querying them for LSP
purposes (e.g., "what commands start with 'Mes'?") requires ad-hoc iteration.

**Needed:**
- Add indexed query methods:
  - `DatabaseV2::command_names() -> Vec<&str>`
  - `DatabaseV2::command_by_name(name: &str) -> Option<&Command>`
  - `DatabaseV2::search_commands(prefix: &str) -> Vec<&Command>`
  - `ConstantDb::constant_names() -> Vec<&str>`
  - `ConstantDb::search_constants(prefix: &str) -> Vec<(&str, i32)>`
- Include doc strings / parameter info in the returned data so the LSP can show
  hover and signature help.

**Impact:** Medium. Completions and hover depend on this.

### 6. Partial / Incremental Analysis Mode

**Problem:** `Analyzer::analyze` validates the entire file and requires all
symbols to be resolvable. In an editor, some symbols may be temporarily undefined.

**Needed:**
- An `analyze_partial` mode (or a configuration on `Analyzer`) that:
  - Reports unresolved symbols as warnings/notes rather than hard errors.
  - Still builds as complete a symbol table as possible.
  - Does not abort on the first semantic error.
- This pairs with the error-tolerant parser.

**Impact:** High. Without this, the LSP would show no symbols / completions in
any file with a single syntax error.

### 7. Extract a `rotom-syntax` or Stabilize `rotom` as a Library

**Problem:** The `rotom` crate is currently both a CLI binary and a library, but
its API surface is ad-hoc. For `rotom-lsp` to depend on it robustly, we need
versioned, stable library exports.

**Options:**
- **Option A (preferred):** Keep everything in the `rotom` crate but clearly
  document the public API modules (`compiler::`, `database::`, `decompiler::`).
  Add `#[non_exhaustive]` where appropriate. Use semantic versioning.
- **Option B:** Split into `rotom-syntax` (lexer, parser, AST, analysis),
  `rotom-database` (DB loading), and `rotom-codegen` (IR + emitter). The LSP
  would only depend on `rotom-syntax` and `rotom-database`.

**Recommendation:** Start with Option A (stabilize existing exports) to avoid
major refactoring. If the crate grows too large, split later.

**Impact:** Medium. Organizational / API design work.

### 8. Expose Preprocessor State

**Problem:** The LSP needs to know about `#include` and `#define` macros so that
completions include constants from headers.

**Needed:**
- Make the preprocessor module public or expose a function like
  `preprocessor::extract_includes(source) -> Vec<IncludeDirective>`.
- Include span info for each include so the LSP can provide go-to-definition
  from `#include "constants/foo.h"` to the actual header file.

**Impact:** Medium. Needed for accurate completions in decomp projects.

### 9. Add `wasm32` Compilation Target (Future)

**Problem:** Some editors (e.g., Zed's WASM extensions, web-based IDEs) may want
to run the LSP or parser in WASM.

**Needed:**
- Ensure `rotom` compiles for `wasm32-unknown-unknown` by gating or replacing
  file-system-dependent code (`std::fs`, `uxie` C-parser, etc.).
- The LSP itself likely won't run in WASM immediately, but the parser might.

**Impact:** Low / future work.

---

## Development Roadmap

### Phase 0: Foundation (Weeks 1–2)
- [ ] Create `tree-sitter-rotom` repository with initial `grammar.js`.
- [ ] Write tree-sitter tests covering all constructs from `rotoscript_spec.md`.
- [ ] Create `highlights.scm`, `brackets.scm`, `indents.scm`, `outline.scm`.
- [ ] Implement required modifications 1–3 in the main `rotom` crate.

### Phase 1: LSP Skeleton (Weeks 3–4)
- [ ] Scaffold `rotom-lsp` with `tower-lsp` and stdio transport.
- [ ] Implement incremental document sync (`DocumentCache`).
- [ ] Integrate error-tolerant parser and publish diagnostics.
- [ ] Implement required modifications 4–6 in the main `rotom` crate.

### Phase 2: Core Intelligence (Weeks 5–6)
- [ ] Completions: commands, aliases, labels, constants.
- [ ] Hover: command docs from DB, alias values.
- [ ] Document symbols: functions, actions, labels.
- [ ] Go-to-definition: aliases, labels, functions.

### Phase 3: Editor Extensions (Weeks 7–8)
- [ ] VS Code extension with bundled `rotom-lsp`.
- [ ] Zed extension with grammar + LSP registration.
- [ ] Neovim Lua plugin.

### Phase 4: Polish & CI (Weeks 9–10)
- [ ] Semantic tokens (LSP).
- [ ] Signature help.
- [ ] Formatting.
- [ ] CI pipelines for all components.
- [ ] Publish to registries (npm, crates.io, VS Code Marketplace, Zed extensions).

---

## Appendix: Technology Choices

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| Tree-sitter grammar | JavaScript DSL + C parser | Industry standard; powers Zed, Neovim, GitHub |
| LSP server | Rust (`tower-lsp`) | Reuse existing `rotom` library; performance; memory safety |
| VS Code extension | TypeScript (`vscode-languageclient`) | Official Microsoft SDK; well documented |
| Zed extension | Rust (Zed extension API) | Native API; grammar + LSP registration is simple |
| Neovim plugin | Lua (`nvim-treesitter`, built-in LSP) | Zero compiled dependencies for users |
| Position encoding | UTF-16 (LSP default) | Required for VS Code compatibility; Rust side handles conversion |

---

*This plan is a living document. Update it as the language evolves and new editor*
*requirements emerge.*

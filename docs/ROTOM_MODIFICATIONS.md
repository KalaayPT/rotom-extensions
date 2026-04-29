# Required Modifications to the `rotom` Compiler

This document tracks the specific code changes needed in the upstream `rotom`
repository (`~/dev/rotom`) to support `rotom-lsp` and editor tooling.

## Summary Table

| # | Modification | Priority | Effort | Status |
|---|-------------|----------|--------|--------|
| 1 | Error-tolerant parser | **Critical** | High | Not started |
| 2 | Source position utilities (byte ↔ line/col) | **Critical** | Low | Not started |
| 3 | Stabilize lexer as public API | High | Low | Partially done |
| 4 | Public symbol table with spans | **Critical** | Medium | Not started |
| 5 | Database query / search APIs | High | Medium | Not started |
| 6 | Partial analysis mode | **Critical** | High | Not started |
| 7 | Library API stabilization | Medium | Medium | Not started |
| 8 | Preprocessor metadata exposure | Medium | Low | Not started |
| 9 | WASM compatibility (future) | Low | High | Not started |

---

## Detailed Requirements

### 1. Error-Tolerant Parser

**Current behavior:** `Parser::parse_script_file` returns `ParseResult<ScriptFile>`.
On the first unexpected token it returns `Err(CompileError::Parse { span, message })`.

**Required behavior:** A new entry point (e.g., `Parser::parse_script_file_fallible`)
that returns a struct like:

```rust
pub struct ParseTree {
    pub file: ScriptFile,
    pub errors: Vec<CompileError>,
}
```

The parser should **recover** at known synchronization points:
- Newline + keyword (`function`, `action`, `if`, `while`, `match`, `End`, etc.)
- Block terminators (`endif`, `endwhile`, `endmatch`, `EndMovement`)

Implementation sketch:
```rust
impl<'a> Parser<'a> {
    pub fn parse_script_file_fallible(&mut self) -> ParseTree {
        let mut errors = Vec::new();
        let mut aliases = Vec::new();
        let mut items = Vec::new();

        while !self.current_token_is(&TokenType::EOF) {
            if self.current_token_is(&TokenType::Newline) {
                self.advance();
                continue;
            }
            match self.parse_top_level_stmt() {
                Ok(stmt) => { /* categorize as before */ }
                Err(e) => {
                    errors.push(e);
                    self.synchronize();
                }
            }
        }

        ParseTree {
            file: ScriptFile { aliases, items, jump_table_end_marker_count: 1 },
            errors,
        }
    }

    fn synchronize(&mut self) {
        // Skip tokens until we hit a safe boundary
        while !self.current_token_is(&TokenType::EOF) {
            match &self.current_token.kind {
                TokenType::Function | TokenType::Action | TokenType::If
                | TokenType::While | TokenType::Match | TokenType::End => return,
                TokenType::Newline => { self.advance(); return; }
                _ => self.advance(),
            }
        }
    }
}
```

The AST (`StatementKind`) may need an `Error` variant to represent recovered
nodes inline.

**Files to modify:**
- `src/compiler/parser.rs`
- `src/compiler/ast.rs` (add `StatementKind::Error`)
- `src/compiler/mod.rs` (re-export new types)

---

### 2. Source Position Utilities

**Current behavior:** Spans are `Range<usize>` (byte offsets).

**Required behavior:** Conversion to zero-based line and UTF-16 character offset
(as required by LSP).

Implementation sketch:
```rust
// src/compiler/sourcemap.rs (new file)

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Position {
    pub line: u32,      // 0-based
    pub character: u32, // 0-based, UTF-16 code units
}

pub struct SourceMap<'a> {
    source: &'a str,
    line_starts: Vec<usize>,
}

impl<'a> SourceMap<'a> {
    pub fn new(source: &'a str) -> Self { ... }
    pub fn byte_to_position(&self, offset: usize) -> Position { ... }
    pub fn position_to_byte(&self, pos: Position) -> usize { ... }
    pub fn range_to_lsp_range(&self, range: Range<usize>) -> lsp_types::Range { ... }
}
```

Note: UTF-16 character counting is required because LSP defaults to UTF-16.
Rust strings are UTF-8, so conversion must count surrogate pairs for characters
outside the BMP.

**Files to modify:**
- Create `src/compiler/sourcemap.rs`
- Update `src/compiler/mod.rs`
- Optionally add `lsp-types` as a dev-dependency gated behind a feature flag.

---

### 3. Stabilize Lexer as Public API

**Current state:** `pub mod lexer` exists, but some internals may change.

**Required:** Commit to the following stable API surface:
- `Lexer::new(source: &str) -> Lexer`
- `Lexer::next_token(&mut self) -> Token`
- `Lexer::tokenize(self) -> Vec<Token>`
- `Token { kind: TokenType, span: Range<usize> }`
- `TokenType` variants as currently defined.

No code changes needed immediately beyond adding doc comments and possibly
`#[derive(Serialize)]` on `Token` / `TokenType` for easier debugging.

**Files to modify:**
- `src/compiler/lexer.rs` (add docs)
- `src/compiler/token.rs` (add docs, maybe serde)

---

### 4. Public Symbol Table with Spans

**Current state:** `Analyzer::symbols` exists but its type and fields are private
or crate-private.

**Required:** Expose a queryable symbol table.

Current structure (inferred from `analysis.rs` usage):
```rust
pub struct SymbolTable {
    aliases: HashMap<String, AliasInfo>,
    functions: HashMap<String, FunctionInfo>,
    labels: HashMap<String, LabelInfo>,
    // ...
}
```

Required additions:
```rust
#[derive(Debug, Clone)]
pub struct SymbolInfo {
    pub name: String,
    pub kind: SymbolKind,
    pub span: Range<usize>,
    pub def_line: usize, // or use SourceMap
}

pub enum SymbolKind {
    Alias { value: i32 },
    Function { slot: Option<u32> },
    Label,
    Action,
    LocalLabel { parent_function: String },
}

impl SymbolTable {
    pub fn lookup(&self, name: &str) -> Option<&SymbolInfo>;
    pub fn aliases(&self) -> impl Iterator<Item = &SymbolInfo>;
    pub fn functions(&self) -> impl Iterator<Item = &SymbolInfo>;
    pub fn labels(&self) -> impl Iterator<Item = &SymbolInfo>;
    pub fn all_symbols(&self) -> impl Iterator<Item = &SymbolInfo>;
}
```

**Files to modify:**
- `src/compiler/analysis.rs` (refactor symbol structures, make public)
- `src/compiler/mod.rs` (re-export)

---

### 5. Database Query / Search APIs

**Current state:** `DatabaseV2` exposes `commands: HashMap<String, Command>`, but
no search helpers.

**Required:** Add convenience methods for prefix search and fuzzy matching.

```rust
impl DatabaseV2 {
    pub fn command_names(&self) -> Vec<&str> { ... }
    pub fn command_by_name(&self, name: &str) -> Option<&Command> { ... }
    pub fn search_commands(&self, prefix: &str) -> Vec<&Command> { ... }
    pub fn all_conditions(&self) -> &[(&str, u8)] { ... }
}

impl ConstantDb {
    pub fn constant_names(&self) -> Vec<&str> { ... }
    pub fn search_constants(&self, prefix: &str) -> Vec<(&str, i32)> { ... }
}
```

Also, the `Command` struct should expose:
- `doc_summary: Option<String>` — one-line description.
- `params: &[ParamInfo]` — parameter names and types for signature help.

**Files to modify:**
- `src/database.rs`
- `src/lib.rs` (re-export)

---

### 6. Partial Analysis Mode

**Current behavior:** `Analyzer::analyze` returns `Result<(), CompileError>`. It
stops at the first error.

**Required behavior:** `Analyzer::analyze_partial` returns:
```rust
pub struct AnalysisResult {
    pub symbols: SymbolTable,
    pub diagnostics: Vec<CompileError>,
}
```

The analyzer should continue after encountering undefined references, duplicate
definitions, etc., collecting all issues into `diagnostics`.

**Files to modify:**
- `src/compiler/analysis.rs`
- `src/compiler/mod.rs`

---

### 7. Library API Stabilization

**Action items:**
- Add `#![warn(missing_docs)]` to `src/lib.rs` and document all public items.
- Add `#[non_exhaustive]` to public enums that may grow (`CompileError`, `StatementKind`, etc.).
- Define a clear MSRV (Minimum Supported Rust Version).
- Publish `rotom` to crates.io (or at least version it with git tags).

**Files to modify:**
- `src/lib.rs`
- `Cargo.toml` (add description, license, repository for crates.io readiness)

---

### 8. Preprocessor Metadata Exposure

**Current state:** `src/compiler/preprocessor.rs` is crate-private.

**Required:** Expose at minimum:
```rust
pub struct IncludeDirective {
    pub path: String,
    pub span: Range<usize>,
}

pub fn extract_includes(source: &str) -> Vec<IncludeDirective>;
```

This lets the LSP provide go-to-definition on `#include` lines and understand
which constants are in scope.

**Files to modify:**
- `src/compiler/preprocessor.rs` (make module public, add structs)
- `src/compiler/mod.rs`

---

### 9. WASM Compatibility (Future)

**Action items:**
- Audit `std::fs` usage in the library path. Gate it behind `#[cfg(not(target_arch = "wasm32"))]`.
- Check `uxie` dependency for C bindings that won't compile to WASM.
- Consider a `wasm-bindgen` feature flag for parser-only WASM builds.

**Files to modify:**
- `Cargo.toml` (feature flags)
- `src/database.rs` (file-system gating)
- `src/compiler/preprocessor.rs` (file-system gating)

---

## Recommended Order of Implementation

1. **SourceMap (pos #2)** — easy win, needed by everything else.
2. **Stabilize Lexer (pos #3)** — mostly docs.
3. **Error-tolerant Parser (pos #1)** — biggest blocker; do early.
4. **Partial Analysis (pos #6)** — pairs with error-tolerant parser.
5. **Public Symbol Table (pos #4)** — needed for LSP intelligence.
6. **Database Search APIs (pos #5)** — needed for completions/hover.
7. **Preprocessor Exposure (pos #8)** — polish for decomp projects.
8. **Library Stabilization (pos #7)** — release engineering.
9. **WASM (pos #9)** — future stretch goal.

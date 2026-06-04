# Rotom Grammar Reference

This is a human-readable reference for the Rotom surface syntax. The canonical
machine-readable grammar is `tree-sitter-rotom/grammar.js`.

## Lexical Structure

### Comments
```rotom
// line comment
/* block comment */
```

### Identifiers
- Start with letter or `_`
- Followed by alphanumeric or `_`
- Case-sensitive

### Numbers
- Decimal: `42`, `-7`
- Hexadecimal: `0x1A`, `0x4000`

### Labels
- Top-level: `Name:`
- Inline/local: `.name:`

### Preprocessor Directives
Directives are top-level declarations used for C constant resolution.

```rotom
#include "constants/items.h"
#define STARTER_ITEM ITEM_POTION
```

## Program Structure

```rotom
// Aliases (global)
alias 0x800C as VAR_RESULT

// Public script (jump table entry)
script Main #1:
    Message 1
    End

// Private label
Helper:
    Message 2
    Return

// Action (movement block)
action WalkAway:
    WalkDown 3
    FaceDown
EndMovement
```

## Control Flow

### If
```rotom
if VAR_RESULT == 1 then
    Message 1
else
    Message 2
endif
```

### While
```rotom
while VAR_COUNTER < 10 do
    AddVar VAR_COUNTER, 1
endwhile
```

### Match
```rotom
match VAR_RESULT with
    case 0:
        Message 1
    case 1, 2:
        Message 2
    else:
        Message 0
endmatch
```

## Expressions

- Arithmetic: `1 + 2 * 3`
- Comparison: `==`, `!=`, `<`, `>`, `<=`, `>=`
- Logical: `&&`/`and`, `||`/`or`, `!`/`not`
- Calls: `CheckPlayerOnBike()`, `AddItem(ITEM_POTION, 5)`

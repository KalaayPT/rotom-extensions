; Rotom syntax highlighting (bundled in Zed extension)

[
  "if" "then" "else" "endif"
  "while" "do" "endwhile"
  "match" "with" "case" "endmatch"
  "Jump" "EndMovement"
  "script" "action"
  "alias" "as"
] @keyword

[
  (break_statement)
  (return_statement)
  (end_statement)
] @keyword

(boolean) @boolean
(number) @number
(slot_id) @number
(string) @string
(escape_sequence) @escape
(comment) @comment

[
  "==" "!=" "<=" ">=" "<" ">" "&&" "||" "and" "or"
  "+" "-" "*"
  "!" "not"
  "(" ")" "[" "]" "," "#" ":"
] @operator

(preprocessor_directive) @preproc

(expression (identifier) @variable)

(alias_statement
  "as"
  (identifier) @variable)

(function_header name: (identifier) @type)
(action_definition name: (identifier) @type)
(label_definition name: (identifier) @type)
(local_label_definition (local_label) @type)

(jump_statement "Jump" (identifier) @type)
(jump_statement "Jump" (local_label) @type)

(command_statement name: (identifier) @function.call)
(movement_statement command: (identifier) @function.call)
(call_expression function: (identifier) @function.call)

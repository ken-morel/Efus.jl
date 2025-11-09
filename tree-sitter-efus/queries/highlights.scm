; Keywords
(if_statement "if" @keyword.control.conditional)
(else_if_clause "elseif" @keyword.control.conditional)
(else_clause "else" @keyword.control.conditional)
(for_statement "for" @keyword.control.repeat)
("end" @keyword.control)

; Component Calls
(component_call
  name: (identifier) @type)

; Properties
(property_assignment
  key: (identifier) @attribute)
(grouped_property_assignment
  group: (identifier) @attribute
  key: (identifier) @attribute)
(splat_operator (identifier) @attribute)

; Snippets
(snippet_definition
  name: (identifier) @function)
(parameter
  name: (identifier) @variable.parameter)
(parameter
  type: (identifier) @type.builtin)

; Literals
(string_literal) @string
(number_literal) @constant.numeric
(boolean_literal) @constant.builtin.boolean

; Punctuation
("(" @punctuation.bracket)
(")" @punctuation.bracket)
("[" @punctuation.bracket)
("]" @punctuation.bracket)
("=" @operator)
(":" @operator)
("::" @operator)
("..." @operator)

; Comments
(comment) @comment.line

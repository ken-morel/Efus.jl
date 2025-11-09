; extends

((julia_block) @injection.content
  (#set! injection.language "julia"))

((if_statement
  condition: (expression) @injection.content)
  (#set! injection.language "julia"))

((for_statement
  collection: (expression) @injection.content)
  (#set! injection.language "julia"))

((for_statement
  iterator: (for_iterator) @injection.content)
  (#set! injection.language "julia"))

((property_assignment
  value: (expression) @injection.content)
  (#set! injection.language "julia"))

((grouped_property_assignment
  value: (expression) @injection.content)
  (#set! injection.language "julia"))

((parameter
  default: (expression) @injection.content)
  (#set! injection.language "julia"))
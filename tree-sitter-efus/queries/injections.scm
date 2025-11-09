; extends

((julia_block) @julia
  (#set! "injection.language" "julia"))

((if_statement
  condition: (_) @julia)
  (#set! "injection.language" "julia"))

((for_statement
  iterator: (_) @julia)
  (#set! "injection.language" "julia"))

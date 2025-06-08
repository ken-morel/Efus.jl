function parsenextstatementorfragment!(parser)::Union{AbstractStatementFragment,AbstractStatement,Nothing,AbstractError}
  skipemptylines!(parser)
  parser.index > length(parser.text) && return nothing
  parser.text[parser.index:end] ⊆ (SPACES * '\n') && return nothing
  statement = parsestatementorfragment!(parser)
  iserror(statement) && return statement
  statement === nothing && return SyntaxError("Unexpected statement", ParserStack(parser, AFTER, "in statement"))
  statement
end

function parsestatementorfragment!(parser::Parser)::Union{AbstractStatement,AbstractStatementFragment,Nothing,AbstractError}
  resetiferror(parser) do
    tests = [parsecomment!, parseendfragment!, parseeiffragment!, parseusing!, parsetemplatecall!]
    for test! in tests
      value = test!(parser)
      value === nothing || return value
    end
    nothing
  end
end
function parseendfragment!(parser::Parser)::Union{EndStatement,Nothing}
  start = parser.index
  indent = skipspaces!(parser)
  stack = ParserStack(parser, col(parser):(col(parser)+3), "in end statement")
  statement = parsesymbol!(parser)
  if statement == "end"
    EndStatement(indent, stack)
  else
    parser.index = start
    nothing
  end
end
function parsenextstatement!(parser::Parser)::Union{AbstractStatement,AbstractStatementFragment,Nothing,AbstractError}
  statement = parsenextstatementorfragment!(parser)
  iserror(statement) && return statement
  statement === nothing && return nothing
  if statement isa AbstractStatementFragment
    constructstatement!(parser, statement)
  else
    statement
  end
end

function parseusing!(parser::Parser)::Union{EUsing,Nothing,AbstractError}
  resetiferror(parser) do
    start = parser.index
    indent = skipspaces!(parser, false)
    if parsesymbol!(parser) == "using"
      stack = ParserStack(parser, AFTER, "in using statement")
      skipspaces!(parser)
      mod = parsesymbol!(parser)
      skipspaces!(parser)
      mod === nothing && return SyntaxError("Expected module name in using statement", ParserStack(parser, AFTER, "after using keyword"))
      if char(parser) == ':'
        parser.index += 1
        skipspaces!(parser)
        importnames = Symbol[]
        while true
          name = parsesymbol!(parser)
          name === nothing && return SyntaxError("Unexpected tokens in using statement list", ParserStack(parser, AFTER, "in using statement"))
          push!(importnames, Symbol(name))
          skipspaces!(parser)
          char(parser) == '\n' && break
          if char(parser) == ','
            parser.index += 1
            skipspaces!(parser)
          else
            return SyntaxError("Unexpected token in using statement", ParserStack(parser, AT, "in using statement imports list"))
          end
        end
        EUsing(Symbol(mod), importnames, stack, indent)
      else
        EUsing(Symbol(mod), nothing, stack, indent)
      end
    else
      parser.index = start
      nothing
    end
  end
end

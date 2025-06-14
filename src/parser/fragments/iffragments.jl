@enum EIfFragmentType EIfFragmentIf EIfFragmentElseIf EIfFragmentElse


struct EIfFragment <: AbstractStatementFragment
  type::EIfFragmentType
  expression::Union{EExpr,Nothing}
  indent::Int
  stack::ParserStack
end

function parseeiffragment!(parser::Parser)::Union{EIfFragment,Nothing,AbstractEfusError}
  start = parser.index
  indent = skipspaces!(parser)
  nextend = findfirst('\n', aftercursor(parser)) #TODO
  nextend = nextend === nothing ? length(parser.text) : nextend + parser.index - 1
  linestack = ParserStack(parser.filename, LocatedBetween(line(parser), col(parser), col(parser, nextend - 1)), getline(parser), "In if statememt")
  symb = parsesymbol!(parser)
  if symb ∉ ["if", "elseif", "else"]
    parser.index = start
    return
  end

  resetiferror(parser) do
    if symb == "else"
      parser.index += 1 # skip "\n"
      EIfFragment(EIfFragmentElse, nothing, indent, linestack)
    else
      expr = parseeexpr!(parser, "\n")
      iserror(expr) && return expr
      if expr === nothing
        return SyntaxError("Expected expression after 'if' statement", ParserStack(parser, AFTER, "in if expression"))
      end
      parser.index += 1 # skip "\n"
      EIfFragment(EIfFragmentIf, expr, indent, linestack)
    end
  end
end

function constructstatement!(parser::Parser, iffragment::EIfFragment)::Union{AbstractStatement,Nothing,AbstractEfusError}
  if iffragment.type != EIfFragmentIf
    return SyntaxError("Unexpected else or elseif", iffragment.stack)
  end
  resetiferror(parser) do
    branches = EIfStatementBranch[]
    endofif::Bool = false
    condition = iffragment.expression
    statement = nothing
    while !endofif # loop over one branch
      statement = nothing
      branchstatements = AbstractStatement[]
      while true
        statement = parsenextstatementorfragment!(parser) #TODO: Add recursive combining
        if statement isa AbstractStatementFragment && !(statement isa EIfFragment) && !(statement isa EndStatement)
          statement = constructstatement!(parser, statement)
        end
        if statement === nothing # end of file
          return SyntaxError("Expected end after if statement", iffragment.stack)
        end
        iserror(statement) && return statement
        if statement.indent > iffragment.indent

          push!(branchstatements, statement)
        else
          break
        end
      end
      push!(branches, EIfStatementBranch(condition, ECodeBlock(branchstatements)))
      # is it an end or a contiuation
      statement === nothing && break
      if statement.indent == iffragment.indent
        if statement isa EndStatement
          break
        end
        if statement isa EIfFragment
          if statement.type === EIfFragmentElse
            condition = nothing
          elseif statement.type === EIfFragmentElseIf
            condition = statement.expression
          else
            return SyntaxError("Unexpected if within if statement, maybe you meant elseif?", statement.stack)
          end
          continue
        else
          return SyntaxError("If statement was not closed yet", statement.stack)
        end
      else
        return SyntaxError("Unexpected unindent without closing if block", statement.stack)
      end
    end
    EIfStatement(branches, iffragment.indent, ParserStack(parser, BEFORE, "Lines before here"; add=-5))
  end
end

struct EForFragment <: AbstractStatementFragment
    iterable::EExpr
    alias::Symbol
    indent::Int
    stack::ParserStack
end

function parseeforfragment!(parser::Parser)::Union{EForFragment, Nothing, AbstractEfusError}
    return resetiferror(parser) do
        indent = skipspaces!(parser)
        nextend = findfirst('\n', aftercursor(parser)) #TODO
        nextend = nextend === nothing ? length(parser.text) : nextend + parser.index - 1
        linestack = ParserStack(parser.filename, LocatedBetween(line(parser), col(parser), col(parser, nextend - 1)), getline(parser), "In if statememt")
        symb = parsesymbol!(parser)
        symb != "for" && return nothing

        skipspaces!(parser)
        alias = parsesymbol!(parser)
        isnothing(alias) && return SyntaxError("Expected alias in for statement", linestack)
        skipspaces!(parser)
        parsesymbol!(parser) != "in" && return SyntaxError(
            "Expected 'in' in for expression",
            linestack
        )
        expr = parseeexpr!(parser, "\n")
        iserror(expr) && return expr
        if expr === nothing
            return SyntaxError(
                "Expected expression after 'if' statement",
                ParserStack(parser, AFTER, "in if expression"),
            )
        end
        parser.index += 1 # skip "\n"
        EForFragment(expr, Symbol(alias), indent, linestack)
    end
end

function constructstatement!(parser::Parser, forfragment::EForFragment)::Union{AbstractStatement, Nothing, AbstractEfusError}
    return resetiferror(parser) do
        contents = AbstractStatement[]
        while true
            statement = parsenextstatementorfragment!(parser) #TODO: Add recursive combining
            if statement isa AbstractStatementFragment && !(statement isa EndStatement)
                statement = constructstatement!(parser, statement)
            end
            isnothing(statement) && return SyntaxError(
                "Expected end after for loop",
                forfragment.stack,
            )
            iserror(statement) && return statement
            if statement.indent > forfragment.indent
                push!(contents, statement)
            elseif statement isa EndStatement && statement.indent == forfragment.indent
                break
            else
                return SyntaxError("The for code block was not yet closed", statement.stack)
            end
        end
        EForStatement(forfragment.indent, forfragment.alias, forfragment.iterable, ECodeBlock(contents), ParserStack(parser, BEFORE, "Lines before here"; add = -5))
    end
end

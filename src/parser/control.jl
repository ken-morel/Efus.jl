function parse_controlflow!(p::EfusParser)::Union{Ast.ControlFlow, AbstractParseError, Nothing}
    flow = @zig! parse_ifstatement!(p)
    !isnothing(flow) && return flow
    return
end
function parse_ifstatement!(p::EfusParser)::Union{Ast.IfStatement, AbstractParseError, Nothing}
    return ereset(p) do
        b = current_char(p)
        parse_symbol!(p) != :if && return nothing
        e = current_char(p, -1)
        lastcontrol = b * e
        branches = Ast.IfBranch[]
        condition = @zig! parse_jlexpressiontilltoken!(p, r"\n")
        blockstart = p.index
        blockend = p.index
        name = :if
        while true
            skip_spaces!(p)
            b = current_char(p)
            name = parse_symbol!(p)
            e = current_char(p, -1)
            if name == :elseif || name == :else || name == :end
                lastcontrol = b * e
                line = if !isnothing(lastcontrol)
                    lastcontrol.start[1]
                end
                newp = EfusParser(p.text[blockstart:blockend], p.file * "; in $name block at line $line")
                block = @zig! parse!(newp)
                push!(branches, Ast.IfBranch(condition, block))
                if name == :elseif
                    condition = @zig! parse_jlexpressiontilltoken!(p, r"\n")
                    blockstart = p.index
                    blockend = p.index
                elseif name == :else
                    condition = nothing
                    blockstart = p.index
                    blockend = p.index
                elseif name == :end
                    break
                end
            end
            if inbounds(p)
                newline = findnext('\n', p.text, p.index)
                if !isnothing(newline)
                    p.index = newline + 1
                    blockend = p.index
                    continue
                end
            end
            return EfusSyntaxError(
                "Non terminated control flow after here",
                lastcontrol
            )
        end
        return Ast.IfStatement(; branches)
    end
end

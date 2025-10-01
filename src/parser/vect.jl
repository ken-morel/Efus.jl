function parse_vect!(p::EfusParser)::Union{Ast.Vect, AbstractParseError, Nothing}
    return ereset(p) do
        p.text[p.index] != '[' && return
        p.index += 1
        values = Ast.AbstractValue[]
        while true
            skip_spaces!(p; newline = true)
            if !inbounds(p)
                return EfusSyntaxError("Unterminated vector", current_char(p, -1))
            end
            p.text[p.index] == ']' && break
            if p.text[p.index] == ','
                p.index += 1
                continue
            end
            nextvalue = @zig! parse_expression!(p)
            isnothing(nextvalue) && return EfusSyntaxError(
                "Expected expression in vector", current_char(p),
            )
            push!(values, nextvalue)
            skip_spaces!(p; newline = true)
            if !inbounds(p)
                return EfusSyntaxError("Unterminated vector", current_char(p, -1))
            end
            if p.text[p.index] == ','
                p.index += 1
                continue
            elseif p.text[p.index] == ']'
                break
            else
                return EfusSyntaxError("Expected ',' or ']' in vector", current_char(p))
            end
        end
        p.index += 1
        return Ast.Vect(values)
    end
end

function parse_componentcall!(p::EfusParser)::Union{Ast.ComponentCall, Nothing, AbstractParseError}
    return ereset(p) do
        name = nothing
        @zig!n name parse_symbol!(p)
        args = nothing
        @zig!n args parse_componentcallargs!(p)
        Ast.ComponentCall(;
            name,
            arguments = args,
            location = nothing,
        )
    end
end

function parse_componentcallargs!(p::EfusParser)::Union{Vector{Ast.ComponentCallArgument}, AbstractParseError}
    return ereset(p) do
        args = Ast.ComponentCallArgument[]
        while true
            skip_spaces!(p)
            inbounds(p) || break
            pair = nothing
            @zig! pair parse_componentcallargument!(p)
            if isnothing(pair)
                if inbounds(p) && !isspace(p.text[p.index])
                    return EfusSyntaxError("Unexpected token in component call '$(p.text[p.index])'", current_char(p))
                else
                    break
                end
            end
            push!(args, pair)
        end
        return args
    end
end

function parse_componentcallargument!(p::EfusParser)::Union{AbstractParseError, Nothing, Ast.ComponentCallArgument, Nothing}
    return ereset(p) do
        start = current_char(p)
        name = nothing
        @zig!n name parse_symbol!(p)

        if !inbounds(p) || p.text[p.index] != '='
            if !inbounds(p)
                p.index -= 1
            end
            return EfusSyntaxError(
                "Missing equal sign after key in key=value pair in tempate call argument",
                current_char(p)
            )
        else
            p.index += 1
        end
        value = nothing
        @zig! value parse_expression!(p)

        if isnothing(value)
            return EfusSyntaxError(
                "Missing value in key=value pair",
                current_char(p)
            )
        end
        return Ast.ComponentCallArgument(;
            name,
            value,
            location = start * current_char(p, -1)
        )
    end
end

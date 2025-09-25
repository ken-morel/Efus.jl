function parse_componentcall!(p::EfusParser)::Union{Ast.ComponentCall, Nothing, AbstractParseError}
    return ereset(p) do
        name = @zig!n parse_symbol!(p)
        args = @zig!n parse_componentcallargs!(p)
        Ast.ComponentCall(;
            name,
            arguments = args[1],
            splats = args[2],
            location = nothing,
            parent = nothing,
            children = [],
        )
    end
end

function parse_componentcallargs!(p::EfusParser)::Union{
        Tuple{Vector{Ast.ComponentCallArgument}, Vector{Ast.ComponentCallSplat}},
        AbstractParseError,
    }
    return ereset(p) do
        args = Ast.ComponentCallArgument[]
        splats = Ast.ComponentCallSplat[]
        while true
            skip_spaces!(p)
            inbounds(p) || break
            splat = @zig! parse_componentcallsplat!(p)
            if !isnothing(splat)
                push!(splats, splat)
                continue
            end
            pair = @zig! parse_componentcallargument!(p)
            if isnothing(pair)
                if inbounds(p) && !isspace(p.text[p.index])
                    return EfusSyntaxError("Unexpected token in component call '$(p.text[p.index])'", current_char(p))
                else
                    break
                end
            end
            push!(args, pair)
        end
        return (args, splats)
    end
end

function parse_componentcallsplat!(p::EfusParser)::Union{Ast.ComponentCallSplat, AbstractParseError, Nothing}
    return ereset(p) do
        start = current_char(p)
        name = parse_symbol!(p)
        if !isnothing(name) && inbounds(p) && p.text[p.index] == '.'
            if !(length(p.text) >= p.index + 2 && p.text[p.index:(p.index + 2)] == "...")
                return EfusSyntaxError("Malformed splat operator after name", current_char(p))
            end
            p.index += 3
            return Ast.ComponentCallSplat(name, start * current_char(p, -1))
        end
    end
end
function parse_componentcallargument!(p::EfusParser)::Union{AbstractParseError, Nothing, Ast.ComponentCallArgument, Nothing}
    return ereset(p) do
        start = current_char(p)
        name = @zig!n parse_symbol!(p)

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
        if p.index == '|'
            p.index += 1
            skip_emptylines!(p)
            skip_spaces!(p)
        end
        value = @zig! parse_expression!(p)

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

function parse_number!(p::EfusParser)::Union{Nothing, Real}
    m = match(r"^\d+(?:\.\d*)?", p.text[p.index:end])
    return if !isnothing(m)
        p.index += length(m.match)
        if '.' ∈ m.match
            parse(Float64, m.match)
        else
            parse(Int64, m.match)
        end
    end
end

function parse_geometry_part!(p::EfusParser; force_sign::Bool = true)::Union{AbstractParseError, Nothing, Tuple{Char, Vector{Real}, Union{Symbol, Nothing}}}
    return ereset(p) do
        start = current_char(p)

        hassign = inbounds(p) && p.text[p.index] ∈ "+-"
        sign::Char = if hassign
            s = p.text[p.index]
            p.index += 1
            !inbounds(p) && return EfusSyntaxError("Invalid geometry: unexpected end of input after sign", start)
            s
        else
            force_sign && return nothing
            '+'
        end

        numbers = Real[]
        while true
            n = parse_number!(p)
            if isnothing(n)
                if isempty(numbers)
                    return EfusSyntaxError("Invalid geometry: missing number", start * current_char(p))
                end
                break
            end
            push!(numbers, n)

            if !inbounds(p) || p.text[p.index] != 'x'
                break
            end
            p.index += 1 # consume 'x'
        end

        unit = parse_symbol!(p)

        return (sign, numbers, unit)
    end
end


function parse_geometry!(p::EfusParser)::Union{AbstractParseError, Nothing, Geometry, Size, Real}
    if !inbounds(p) || (!isdigit(p.text[p.index]) && p.text[p.index] ∉ "+-")
        return nothing
    end

    return ereset(p) do
        start_loc = current_char(p)
        signs = Vector{Char}()
        parts = Vector{Vector{Real}}()
        units = Vector{Union{Symbol, Nothing}}()
        isfirst = true

        while true
            part = parse_geometry_part!(p; force_sign = !isfirst)

            if part isa AbstractParseError
                return part
            end
            if isnothing(part)
                break
            end

            s, num, u = part
            push!(signs, s)
            push!(parts, num)
            push!(units, u)

            isfirst = false
        end

        if inbounds(p) && !isspace(p.text[p.index])
            return EfusSyntaxError("Unexpected token after geometry", current_char(p))
        end

        if isempty(parts)
            return EfusSyntaxError("Failed to parse geometry", start_loc)
        end

        # Simplify output for common cases
        if length(parts) == 1
            val = parts[1][1] * (signs[1] == '-' ? -1 : 1)

            if length(parts[1]) == 1
                return val
            elseif length(parts[1]) == 2
                return Size(promote(val, parts[1][2])..., units[1])
            end
        end

        return Geometry(signs, parts, units)
    end
end

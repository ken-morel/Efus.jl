abstract type AbstractParseError <: EfusError end

macro zig!(expression::Union{Expr, Symbol})
    var = gensym(:__zig_value__)
    return quote
        $(LineNumberNode(__source__.line, __source__.file))
        let $(esc(var)) = $(esc(expression))
            if $(esc(var)) isa $AbstractParseError
                return $(esc(var))
            end
            $(esc(var))
        end
    end
end
macro zig!n(expression::Union{Expr, Symbol})
    var = gensym(:__zig!n_value__)
    return quote
        $(LineNumberNode(__source__.line, __source__.file))
        let $(esc(var)) = $(esc(expression))
            if $(esc(var)) isa $AbstractParseError || isnothing($(esc(var)))
                return $(esc(var))
            end
            $(esc(var))
        end
    end
end
macro zig!r(expression::Union{Expr, Symbol})
    var = gensym(:__zig!r_value__)
    return quote
        $(LineNumberNode(__source__.line, __source__.file))
        let $(esc(var)) = $(esc(expression))
            if $(esc(var)) isa $AbstractParseError || !isnothing($(esc(var)))
                return $(esc(var))
            end
            $(esc(var))
        end
    end
end


struct EfusSyntaxError <: AbstractParseError
    parser::Union{Nothing, EfusParser}
    message::String
    location::Ast.Location
end

function Base.showerror(io::IO, e::EfusSyntaxError)
    printstyled(io, "EfusSyntaxError", color = :red, bold = true)
    print(io, ": ", e.message, "\n")

    print(io, "In ")
    printstyled(io, e.location.file, color = :blue, bold = true)
    print(io, " at line ")
    print(io, e.location.start[1])
    printstyled(io, ", column ")
    printstyled(io, e.location.start[2])
    print(io, ":\n")

    if !isnothing(e.parser)
        ln = split(e.parser.text, "\n")[e.location.start[1]]

        print(io, ln, "\n")

        start = e.location.start[2]
        stop = e.location.start[1] == e.location.stop[1] ? e.location.stop[2] : length(ln)
        print(io, " "^(start - 1))
        printstyled(io, "^"^(stop - start + 1); color = :red, bold = true)
    end
    return
end

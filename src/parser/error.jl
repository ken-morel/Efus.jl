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


function try_parse!(p::EfusParser)
    content = parse!(p)
    if content isa AbstractParseError
        throwparseerror(p, content)
    elseif content isa EfusError
        throw(content)
    end
    return content
end

struct EfusSyntaxError <: AbstractParseError
    message::String
    location::Ast.Location
end

function throwparseerror(p::EfusParser, e::EfusSyntaxError)
    loc = "In $(e.location.file) at line $(e.location.start[1]), column $(e.location.start[2]):"
    ln = split(p.text, '\n')[e.location.start[1]]
    start = e.location.start[2]
    stop = e.location.start[1] == e.location.stop[1] ? e.location.stop[2] : length(ln)
    trace = " "^(start - 1) * "^"^(stop - start + 1)
    msg = "Efus.Parser.EfusSyntaxError: " * e.message
    error(join([msg, loc, ln, trace], "\n"))
end

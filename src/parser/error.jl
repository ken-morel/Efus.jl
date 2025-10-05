mutable struct ParseError <: IonicEfus.EfusError
    message::String
    location::Location
    line::Union{String, Nothing}
    ParseError(msg::String, loc::Location) = new(msg, loc, nothing)
end

function Base.showerror(io::IO, err::ParseError)
    printstyled(io, "IonicEfus.Parser.ParseError: "; color = :red, bold = true)
    println(io, err.message)
    Tokens.show_location(io, err.location)
    println(io)
    if !isnothing(err.line)
        Lexer.print_lexed(err.line; fallback = false)
    else
        printstyled(io, "Traceback line unknown"; color = :yellow, italic = true)
    end
    println()
    printstyled(
        io,
        " "^(err.location.start.col - 1),
        "^"^(err.location.stop.col - err.location.start.col + 1);
        color = :light_red,
        bold = :true,
        blink = :true,
    )
    # println(err)
    return
end

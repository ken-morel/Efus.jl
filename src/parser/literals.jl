function parseegeometry!(
        parser::Parser
    )::Union{EGeometry, EInt, EDecimal, Nothing, AbstractEfusError}
    !isdigit(char(parser)) && char(parser) ∉ "-+" && return nothing
    return resetiferror(parser) do
        ln = line(parser)
        startcol = col(parser)
        endcol = startcol
        parts = Union{Missing, Vector{Union{Int, Float64}}}[]
        signs = Char[]
        units = Union{Nothing, Symbol}[]
        while inbounds(parser)  # loop arrounds parts seperated by + or -
            # take the sign
            if char(parser) ∉ "+-"
                if isdigit(char(parser))
                    sign = '+'
                else
                    break
                end
            else
                sign = char(parser)
                nextinline!(parser)
            end
            # take the value(or missing)
            value = if isdigit(char(parser))
                args = Union{Float64, Int}[]
                while true  # loop arround part items sep by x
                    number = parseedecimal!(parser; checkafter = false, allowint = true).value
                    iserror(number) && return number
                    push!(args, number)
                    if !inbounds(parser) || char(parser) != 'x'
                        break
                    else
                        nextinline!(parser)
                    end
                end
                args
            else
                missing
            end
            # take the unit
            unit = if inbounds(parser)  # not another x of course /\
                parsesymbol!(parser)
            end
            push!(parts, value)
            push!(signs, sign)
            push!(units, isnothing(unit) ? nothing : Symbol(unit))
            if col(parser) > endcol
                endcol = col(parser)
            end
        end
        if length(parts) == 0  # not suppose to happen
            nothing
        elseif length(parts) == 1 && !ismissing(parts[1]) && length(parts[1]) == 1
            # just a simple literal
            value = parts[1][1]
            value isa Int ? EInt(value) : EDecimal(value)
        else
            EGeometry(
                parts,
                signs,
                units,
                ParserStack(
                    parser.filename,
                    LocatedBetween(ln, startcol, endcol),
                    getline(parser),
                    "In geometry spec",
                ),
            )
        end

    end
end
function parseeint!(parser::Parser; checkafter::Bool = true)::Union{EInt, Nothing, AbstractEfusError}
    char(parser) in "+-" || isdigit(char(parser)) || return nothing
    return resetiferror(parser) do
        start = parser.index
        if char(parser) in "-+"
            val = nextinline!(parser, "in integer literal")
            iserror(val) && return val
        end
        while true
            if char(parser) == ' '
                break
            elseif !isdigit(char(parser))
                checkafter && return SyntaxError("Unexpected symbols in integer literal", ParserStack(parser, AT, "in integer literal"))
                break
            end
            if iserror(nextinline!(parser))
                parser.index += 1
                break
            end
        end
        EInt(parse(Int, beforecursor(parser)[start:(end - 1)]))
    end
end
function parseedecimal!(
        parser::Parser;
        allowint::Bool = false, checkafter::Bool = true,
    )::Union{EDecimal, EInt, Nothing, AbstractEfusError}
    char(parser) in "+-" || isdigit(char(parser)) || return nothing
    return resetiferror(parser) do
        start = parser.index
        if char(parser) in "-+"
            val = nextinline!(parser, "in decimal literal")
            iserror(val) && return val
        end
        dec = false
        while true
            if char(parser) == '.'
                dec && return SyntaxError("Second decimal point in decimal literal", ParserStack(parser, AT, "in decimal literal"))
                dec = true
            elseif char(parser) == ' '
                break
            elseif !isdigit(char(parser))
                checkafter || break
                return SyntaxError("Unexpected charater in decimal literal", ParserStack(parser, AT, "in integer literal"))
            end
            if iserror(nextinline!(parser))
                parser.index += 1
                break
            end
        end
        literal = parser.text[start:(parser.index - 1)]
        if allowint && '.' ∉ literal
            EInt(parse(Int, literal))
        else
            EDecimal(parse(Float32, literal))
        end
    end
end
fixindex(text::String, index::UInt) = findlast(<=(index), collect(eachindex(text)))
function parseestring!(parser::Parser)::Union{EString, Nothing, AbstractEfusError}
    char(parser) != '"' && return nothing
    parser.index += 1
    start = parser.index
    while true
        nextslash = findnext('\\', parser.text, parser.index)
        nextquote = findnext('"', parser.text, parser.index)
        if isnothing(nextquote)
            return SyntaxError(
                "Could not find closing '\"'",
                ParserStack(
                    parser,
                    col(parser, start):col(parser, parser.index),
                    "in string literal",
                ),
            )
        elseif !isnothing(nextslash) && nextslash == nextquote - 1
            parser.index = nextquote + 1
        else
            parser.index = nextquote + 1
            break
        end
    end
    return EString(
        parser.text[
            fixindex(parser.text, start):fixindex(parser.text, parser.index - 2),
        ]
    )
end
function parsefusesymbol!(parser::Parser)::Union{ESymbol, EBool, ENothing, Nothing}
    !isletter(char(parser)) && return nothing
    word = parsesymbol!(parser)
    isnothing(word) && return nothing
    word ∈ ["true", "false"] && return EBool(word == "true")
    word == "nothing" && return ENothing(nothing)
    return ESymbol(Symbol(word))
end
function parseeexpr!(
        parser::Parser,
        endtoken::Union{String, Nothing} = nothing,
    )::Union{AbstractEfusError, EExpr, Nothing}
    bracketed = endtoken === nothing
    bracketed && char(parser) != '(' && return nothing
    return resetiferror(parser) do
        start = parser.index
        count = Int(bracketed)
        while true
            parser.index += 1
            inbounds(parser) || return SyntaxError(
                "Unterminated expression",
                ParserStack(parser, AT, "in expression literal"),
            )
            if char(parser) == '('
                count += 1
            elseif char(parser) == ')'
                count -= 1
                count == 0 && bracketed && break
            elseif !bracketed && startswith(aftercursor(parser), endtoken) && count == 0
                break
            end
        end
        stack = ParserStack(parser, col(parser, start):col(parser), "in efus expr")
        try
            expr = Meta.parse(parser.text[(start + 1):(parser.index - 1)])
            if bracketed
                parser.index += 1 #skip last bracket
            end
            return EExpr(expr, stack)
        catch exception
            return EJuliaException("Error parsing julia snippet, error following", exception, stack)
        end
    end
end


function parsernamebinding!(parser::Parser)::Union{ENameBinding, Nothing, AbstractEfusError}
    char(parser) == '&' || return nothing
    start = parser.index
    parser.index += 1 #skip '&'
    name = parsesymbol!(parser)
    if name === nothing
        parser.index = start
        return nothing
    end
    return ENameBinding(
        Symbol(name),
        ParserStack(parser, col(parser, start):col(parser), "in name binding"),
    )
end


function parsevalue!(parser::Parser)::Union{EObject, Nothing, AbstractEfusError}
    tests = [
        parseestring!, parsernamebinding!, parseeexpr!, parsefusesymbol!, parseegeometry!,
    ]
    for test! in tests
        value = test!(parser)
        value === nothing || return value
    end
    return nothing
end

Base.@kwdef mutable struct Parser
    text::String
    index::UInt = 1
    filename::String = "<efus source>"
end

inbounds(parser::Parser) = parser.index <= length(parser.text)

beforecursor(parser::Parser)::String = parser.text[begin:min(parser.index, length(parser.text))]
beforecursor(parser::Parser, idx::Integer)::String = parser.text[begin:min(idx, length(parser.text))]
aftercursor(parser::Parser)::String = parser.text[min(parser.index, length(parser.text)):end]
aftercursor(parser::Parser, idx::Integer)::String = parser.text[min(idx, length(parser.text)):end]
line(parser::Parser)::Int = 1 + count('\n', beforecursor(parser))
line(parser::Parser, idx::Integer)::Integer = one(idx) + count('\n', beforecursor(parser, idx))
char(parser::Parser)::Union{Char, Nothing} = parser.index <= length(parser.text) ? parser.text[parser.index] : nothing
char(parser::Parser, idx::Integer)::Union{Char, Nothing} = idx <= length(parser.text) ? parser.text[idx] : nothing
function col(parser::Parser)::Int
    text = beforecursor(parser)
    after_last_newline = '\n' in text ? findlast('\n', text) + 1 : 1
    return length(text[after_last_newline:end])
end
function col(parser::Parser, idx::Integer)::Int
    text = beforecursor(parser, idx)
    after_last_newline = '\n' in text ? findlast('\n', text) + 1 : 1
    return length(text[after_last_newline:end])
end
function skipspaces!(parser::Parser, canbenothing::Bool = true)::Union{Int, Nothing}
    start = parser.index
    while parser.index <= length(parser.text) && char(parser) in SPACES
        parser.index += 1
    end
    canbenothing && parser.index == start && return nothing
    return parser.index - start
end
location(parser::Parser)::Tuple{Int, Int} = (line(parser), col(parser))
function ParserStack(parser::Parser, side::LocatedArroundSide, inside::String; add::Int = 0)::ParserStack
    parser.index += add
    stack = ParserStack(parser.filename, LocatedArround(side, location(parser)...), getline(parser), inside)
    parser.index -= add
    return stack
end
function ParserStack(parser::Parser, range::UnitRange{<:Integer}, inside::String; add::Int = 0)::ParserStack
    parser.index += add
    stack = ParserStack(parser.filename, LocatedBetween(line(parser), first(range), last(range)), getline(parser), inside)
    parser.index -= add
    return stack
end
function getline(parser::Parser)::String
    return split(parser.text, '\n')[line(parser)]
end
function parsefile(path::String)::ECode
    return parse!(Parser(; file = path))
end
function parse!(parser::Parser)::Union{ECode, AbstractEfusError}
    statements = AbstractStatement[]
    while true
        statement = parsenextstatement!(parser)
        statement === nothing && break
        iserror(statement) && return statement
        push!(statements, statement)
    end
    return ECode(ECodeBlock(statements), parser.filename)
end

abstract type AbstractStatementFragment end

struct EndStatement <: AbstractStatement
    indent::Int
    stack::ParserStack
end

include("fragments/iffragments.jl")
include("fragments/forfragment.jl")

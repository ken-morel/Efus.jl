const SnippetFunction = FunctionWrapper{Vector{Component}, Tuple{}}

struct Snippet{T} where {T <: NamedTuple}
    fn::SnippetFunction
end

function Snippet{T}(fn::Function) where {T}
    return Snippet(SnippetFunction(fn))
end

# I hope kwargs are internally represented as NamedTuple
(sn::Snippet)(args...) = sn.fn(args...)

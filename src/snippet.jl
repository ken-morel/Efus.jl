const SnippetFunction{T} = FunctionWrapper{Vector{Component, Tuple{T}}}
struct Snippet{T} where {T <: NamedTuple}
    fn::SnippetFunction{T}
end
function Snippet{T}(fn::Function) where {T}
    return Snippet(SnippetFunction{T}(fn))
end

(sn::Snippet)(args...) = sn.fn(args) # I hope kwargs are internally represented as NamedTuple

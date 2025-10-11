export Snippet, @Snippet

"""
    struct Snippet{T <: NamedTuple}
        fn::Function
    end

A snippet is a simple typed container for a function returning
a component, or list of components. It's help is just 
for type checking and multiple dispatch.
"""
struct Snippet{T <: NamedTuple}
    fn::Function

    """
        Snippet{T}(fn::Function) where T <: NamedTuple
        Snippet(::Type{T}, fn::Function) where T <: NamedTuple
        Snippet(fn::Function, ::Type{T}) where T <: NamedTuple

    Creates a snippet with the specified type
    """
    function Snippet{T}(fn::Function) where {T <: NamedTuple}
        returns = Base.return_types(fn)
        if length(returns) !== 1 || !(returns[1] <: AbstractVector{<:Component})
            @warn "Snippets should return Vector{<:Component}, but $fn returns $returns"
        end
        return new{T}(fn)
    end
end
Snippet(::Type{T}, fn::Function) where {T <: NamedTuple} = Snippet{T}(fn)
Snippet(fn::Function, ::Type{T}) where {T <: NamedTuple} = Snippet{T}(fn)

"Call the snippet inner function with the passed arguments"
(sn::Snippet)(; args...) = sn.fn(; args...)

macro Snippet(expr::Expr)
    expr.head == :curly && error("Invalid snippet expression $expr")
    types = []
    names = []
    for arg in expr.args
        if arg isa Expr && arg.head == :(::)
            push!(names, arg.args[1])
            push!(types, arg.args[2])
        elseif arg isa Symbol
            push!(names, arg)
            push!(types, :Any)
        else
            error("Invalid snippet def")
        end
    end
    namedtupletype = Expr(
        :curly,
        :NamedTuple,
        Expr(:tuple, QuoteNode.(names)...),
        Expr(:curly, Tuple, types...),
    )
    return esc(Expr(:curly, Snippet, namedtupletype))

end

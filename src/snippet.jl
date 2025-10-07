export Snippet


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

    function Snippet(fn::Function)
        returns = Base.return_types(fn)
        if length(returns) !== 1 || !(returns[1] <: AbstractVector{<:Component})
            @warn "Snippets should return Vector{<:Component}, but $fn returns $returns"
        end
        return new(fn)
    end
end

"Call the snippet inner function with the passed arguments"
(sn::Snippet)(; args...) = sn.fn(; args...)

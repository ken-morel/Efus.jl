export Snippet

"""
    const Snippet{T} = FunctionWrapper{Vector{<:AbstractComponent}, T}

A snippet is a functionwrapper which returns child components from 
a tuple of arguments of type T.
"""
const Snippet{T} = FunctionWrapper{Vector{<:AbstractComponent}, T}

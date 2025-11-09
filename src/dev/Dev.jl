"""
    module Dev

Developer tools for using and introspecting
components or debugging code.
"""
module Dev
using ..IonicEfus: Component, IonicEfus
using StructUtils

const StructStyle = StructUtils.DefaultStyle()

"""
    struct Param

Stores the informatin about
a component's parameter.
"""
struct Param
    name::Symbol
    type::Type
    default::Union{Nothing, Some}
    doc::Union{Nothing, String}
end

"""
    @generated function params(c)::Vector{Param}

Returns a vector of [`Param`](@ref) which
contains information about the component
parameters.
"""
@generated function params(c)::Vector{Param}
    params = Param[]
    defaults = StructUtils.fielddefaults(StructStyle, c)
    docs = StructUtils.fieldtags(StructStyle, c)
    for (name, type) in IonicEfus.params(c)
        default = get(defaults, name, nothing)
        ntdocs = get(docs, name, nothing)
        docs::Union{String, Nothing} = nothing
        docs = if ntdocs isa NamedTuple
            get(ntdocs, :doc, nothing)
        elseif ntdocs isa String
            ntdocs
        end
        push!(params, Param(name, type, default, docs))
    end
    return params
end

end

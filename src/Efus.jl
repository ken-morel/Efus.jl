module Efus

using FunctionWrappers: FunctionWrapper
abstract type EfusError <: Exception end


include("./component.jl")


include("./Ast.jl")


include("./objects.jl")
include("./snippet.jl")

include("./reactants.jl")

include("./gen/Gen.jl")

include("./parser/Parser.jl")

include("./macros.jl")
include("./display.jl")

include("./dev.jl")

using .Dev
export codegen_string

using .Parser
export EfusError, EfusParser, try_parse!, try_parse, efus_parse

function cleanchildren(children::Vector)
    children isa Vector{<:AbstractComponent} && return children
    final = AbstractComponent[]
    for child in children
        if child isa AbstractComponent
            push!(final, child)
        elseif child isa AbstractVector
            append!(final, cleanchildren(child))
        elseif !isnothing(child)
            error(
                "Component was passed an unexpected child of type $(typeof(child)): $child. " *
                    "Make sure it either returns a component, a vector of components, or nothing."
            )

        end
    end
    return final
end


end # module Efus

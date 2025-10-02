module Gen
import ..Ast
import ..IonicEfus
import ..Ionic

"""
    function generate end

Generates julia corresponding to the 
efus ast expression.
"""
function generate end

include("./root.jl")
include("./statements.jl")
include("./snippet.jl")
include("./control.jl")
include("./values.jl")
include("./ionic.jl")

generate(node::Ast.AbstractStatement) = error("Generation not implemented for this node type: $(typeof(node))")

generate(value::Ast.AbstractValue) = error("Unsupported generating code for $value")


# We need to generate code for values, too.
end # module Gen

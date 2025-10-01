module Gen
import ..Ast
import ..Efus

include("./root.jl")
include("./statements.jl")
include("./snippet.jl")
include("./control.jl")
include("./values.jl")
include("./fuss.jl")


# We need to generate code for values, too.
end # module Gen

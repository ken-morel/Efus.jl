module Gen
import ..Ast
import ..Efus
import ..Ionic

include("./root.jl")
include("./statements.jl")
include("./snippet.jl")
include("./control.jl")
include("./values.jl")
include("./ionic.jl")


# We need to generate code for values, too.
end # module Gen

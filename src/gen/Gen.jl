"""
Code generator module, receives an ast structure
and generates code using the [`generate`](@ref)
function.
"""
module Gen

export generate

import ..Ast
import ..IonicEfus
import ..Ionic

struct CodeGenerationError <: Exception
    msg::String
end

include("./expression.jl")
include("./statement.jl")


"""
    generate(::T) where {T <: Ast.Expression}

A fallback for Ast nodes which don't support code
generation.
"""
function generate(::T) where {T <: Ast.Expression}
    error("Code generation not supported for $T")
end

end # module Gen

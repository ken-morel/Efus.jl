"""
Code generator module, receives an ast structure
and generates code using the [`generate`](@ref)
function.
"""
module Gen
import ..Ast
import ..IonicEfus
import ..Ionic

"""
The code generation function, receives an instance
of [`Ast.Expression`](@ref) or [`Ast.Statement`](@ref)
and generates juila code.
"""
function generate end

include("./expression.jl")
include("./statement.jl")


function generate(::T) where {T <: Ast.Expression}
    error("Code generation not supported for $T")
end

end # module Gen

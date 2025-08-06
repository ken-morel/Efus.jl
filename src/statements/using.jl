struct EUsing <: AbstractStatement
    mod::Symbol
    imports::Union{Nothing, Vector{Symbol}}
    stack::ParserStack
    indent::Int
end
function eval!(ctx::EfusEvalContext, eusing::EUsing)::Union{AbstractEfusError, Nothing}
    imp = importmodule!(ctx.namespace, eusing.mod, eusing.imports)
    iserror(imp) && prependstack!(imp, eusing.stack)
    return imp
end

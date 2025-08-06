struct TemplateCallArgument
    name::Symbol
    value::EObject
    stack::ParserStack
end

struct TemplateCall <: AbstractStatement
    templatemod::Union{Symbol, Nothing}
    templatename::Symbol
    aliases::Vector{Symbol}
    arguments::Vector{TemplateCallArgument}
    indent::Int
    stack::ParserStack
end
function eval!(ctx::EfusEvalContext, call::TemplateCall)::Union{AbstractEfusError, EObject}
    template = if call.templatemod === nothing
        gettemplate(ctx.namespace, call.templatename)
    else
        tmpl = gettemplate(call.templatemod, call.templatename)
        tmpl === nothing && return NameError("Template named $(call.templatename) not found in module $(call.templatemod)", call.templatename, ctx.namespace, call.stack)
        tmpl
    end
    if template === nothing
        return NameError("Template named $(call.templatename) not found in namespace", call.templatename, ctx.namespace, call.stack)
    end
    while length(ctx.stack) > 0 && last(ctx.stack)[1].indent >= call.indent
        pop!(ctx.stack)
    end
    parent = length(ctx.stack) > 0 ? last(ctx.stack)[2] : nothing
    comp = template(call.arguments, ctx.namespace, parent, call.stack)
    iserror(comp) && return comp
    map(a -> addalias(comp, a), call.aliases)
    push!(ctx.stack, (call, comp))
    return comp
end

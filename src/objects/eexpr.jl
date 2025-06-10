struct EExpr <: EObject
  expr::Union{Expr,Symbol}
  stack
end
function Base.eval(expr::EExpr, names::AbstractNamespace)
  if expr.expr isa Symbol
    n = getname(names, expr.expr, missing)
    n === missing && return NameError("Name $(expr.expr) is not defined in namespace", expr.expr, names, expr.stack === nothing ? ParserStack[] : expr.stack)
    n
  else
    withmodule(names) do mod
      Core.eval(mod, expr.expr)
    end
  end
end

struct ENameBinding <: EObject
  name::Symbol
  stack
  ENameBinding(name::Symbol, stack=[]) = new(name, stack)
end
function Base.eval(binding::ENameBinding, namespace::AbstractNamespace)::AbstractReactant
  getreactant(namespace, binding.name)
end


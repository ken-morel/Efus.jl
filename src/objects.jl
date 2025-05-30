export EObject, AbstractNamespace, resolve, EMirrorObject, EInt, EDecimal, EString, ESize, unit, EBool, ESide, EOrient

abstract type EObject end
abstract type AbstractNamespace <: EObject end
resolve(obj::EObject, _::Union{AbstractNamespace,Nothing}=nothing) = obj
abstract type EMirrorObject{T} <: EObject end
resolve(obj::EMirrorObject{T} where T, _::Union{AbstractNamespace,Nothing}=nothing)::T where T = obj.value
eval(obj::EObject, _::AbstractNamespace) = resolve(obj)

struct EInt <: EMirrorObject{Int}
  value::Int
end
struct EDecimal <: EMirrorObject{Float32}
  value::Float32
end
struct EString <: EMirrorObject{String}
  value::String
end
struct ESize{T,U} <: EObject
  width::Int
  height::Int
  unit::Val{U}
  ESize(width::T, height::T, unit::Union{Symbol,Nothing}=nothing) where T = new{T,unit}(width, height, Val(unit))
end
struct ESide <: EObject
  side::Symbol
end
struct EOrient <: EObject
  orient::Symbol
end
struct EBool <: EMirrorObject{Bool}
  value::Bool
end
struct EExpr <: EObject
  expr::Union{Expr,Symbol}
  stack
end
function eval(expr::EExpr, names::AbstractNamespace)
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
unit(s::ESize)::Union{Symbol,Nothing} = typeof(s.unit).parameters[2] #TODO: Improve this

struct ENameBinding <: EObject
  name::Symbol
  stack::ParserStack
  EVarBinding(name::Symbol,stack::ParserStack=ParserStack[]) = new(name, stack)
end
function eval(binding::ENameBinding, namepace::AbstractNamespace)::AbstractReactant
  getreactant(namespace, binding.name)
end



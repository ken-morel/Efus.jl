struct EEdgeInsets{T,U} <: EObject
  top::T
  right::T
  bottom::T
  left::T
  unit::Val{U}
  function EEdgeInsets(
    t::T, r::T, b::T, l::T, unit::Union{Symbol,Nothing}=nothing,
  ) where T
    new{T,unit}(t, r, b, l, Val(unit))
  end
  function EEdgeInsets(
    a::T, unit::Union{Symbol,Nothing}=nothing,
  ) where T
    new{T,unit}(a, a, a, a, Val(unit))
  end
  function EEdgeInsets(
    h::T, v::T, unit::Union{Symbol,Nothing}=nothing,
  ) where T
    new{T,unit}(v, h, v, h, Val(unit))
  end
end
Base.convert(::Type{EEdgeInsets{T,Any}}, val::T) where {T<:Real} =
  EEdgeInsets(val, nothing)
Base.convert(::Type{EEdgeInsets{T,U}}, val::NTuple{2,<:T}) where {T,U} =
  EEdgeInsets(val..., U)
Base.convert(::Type{EEdgeInsets{T,U}}, val::NTuple{4,<:T}) where {T,U} =
  EEdgeInsets(val..., U)
Base.convert(::Type{EEdgeInsets{T,U}}, val::ESize{<:T,U}) where {T,U} =
  EEdgeInsets(val.width, val.height, U)
function Base.convert(::Type{NTuple{4,T}}, val::EEdgeInsets{<:T}) where T<:Real
  (val.top, val.right, val.bottom, val.left)
end
function Base.convert(::Type{EEdgeInsets{T,Any}}, val::EGeometry) where T<:Real
  try
    if length(val.parts) == 1
      EEdgeInsets(coalesce(val.parts[1][1], zero(T)), val.units[1])
    elseif length(val.parts) == 2
      EEdgeInsets(
        (coalesce.([val.parts[1][1], val.parts[1][1]], (zero(T),)))...,
        val.units[1],
      )
    elseif length(val.parts) == 4
      EEdgeInsets(
        (coalesce.([
            val.parts[1][1], val.parts[2][1], val.parts[3][1], val.parts[4][1]
          ], (zero(T),)))...,
        val.units[1],
      )
    else
      throw("Invalid number of arguments in geometry")
    end
  catch e
    bt = catch_backtrace()
    stacktrace = sprint(showerror, e, bt)
    throw("Cannot convert geometry to EEdgeInsets, $stacktrace")
  end
end


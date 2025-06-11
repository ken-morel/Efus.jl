struct ESize{T,U} <: EObject
  width::T
  height::T
  function ESize(
    width::T, height::T, unit::Union{Symbol,Nothing}=nothing,
  ) where T
    new{T,unit}(width, height)
  end
  function ESize(
    side::T, unit::Union{Symbol,Nothing}=nothing,
  ) where T
    new{T,unit}(side, side)
  end
end
unit(s::ESize)::Union{Symbol,Nothing} = typeof(s.unit).parameters[2] #TODO: Improve this
Base.convert(::Type{Tuple}, val::ESize) =
  (val.width, val.height)

function Base.convert(::Type{ESize}, val::EGeometry)
  try
    if length(val.parts) == 1
      ESize(coalesce(val.parts[1][1], zero(val.parts[1][1])), val.units[1])
    elseif length(val.parts) == 2
      ESize(
        (coalesce.([val.parts[1][1], val.parts[1][1]], (zero(val.parts[1][1]),)))...,
        val.units[1],
      )
      throw("Invalid number of arguments in geometry to convert to Size")
    end
  catch e
    bt = catch_backtrace()
    stacktrace = sprint(showerror, e, bt)
    throw("Cannot convert geometry to ESize, $stacktrace")
  end

end




struct ESquareGeometry{T,U} <: EObject
  pos::NTuple{2,T}
  size::NTuple{2,T}
end
function Base.convert(::Type{ESquareGeometry{T,Any}}, val::EGeometry) where T
  try
    vals::Vector{T} = convert.((T,), catenatenumbers(val),)
    if length(vals) == 4
      ESquareGeometry{T,Any}(tuple(vals[1:2]...), tuple(vals[3:4]...))
    elseif length(vals) == 2
      ESquareGeometry{T,Any}(tuple(vals[1:2]...), (1, 1))
    else
      throw("Not 4 arguments in square geometry")
    end
  catch e
    bt = catch_backtrace()
    stacktrace = sprint(showerror, e, bt)
    throw("Error converting geometry to squaregeometry $stacktrace")
  end
end

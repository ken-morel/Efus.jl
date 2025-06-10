
struct EGeometry <: EObject
  parts::Vector{Union{Vector{Int},Missing}}
  signs::Vector{Char}
  units::Vector{Union{Symbol,Nothing}}
  stack
end
function Base.convert(::Type{Vector{T}}, val::EGeometry) where T<:Real
  [ismissing(val) ? 0 : val[1] for (sign, val) ∈ zip(val.signs, val.parts)]
end
function Base.convert(::Type{NTuple{1,T}}, val::EGeometry) where T<:Real
  vector = convert(Vector{T}, val)
  (vector[1],)
end
function Base.convert(::Type{NTuple{2,T}}, val::EGeometry) where T<:Real
  vector = convert(Vector{T}, val)
  (vector[1], vector[2])
end
function Base.convert(::Type{NTuple{4,T}}, val::EGeometry) where T<:Real
  vector = convert(Vector{T}, val)
  (vector[1], vector[2], vector[3], vector[4])
end

function catenatenumbers(geo::EGeometry, miss::Any=0)
  numbers = Real[]
  for (sign, part) ∈ zip(geo.signs, geo.parts)
    if ismissing(part)
      push!(numbers, miss)
    else
      for n ∈ part
        push!(numbers, sign == '-' ? -n : n)
      end
    end
  end
  numbers
end


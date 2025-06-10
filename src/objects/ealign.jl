abstract type EAlign <: EObject end
struct EVAlign <: EAlign
  side::Symbol
  function EVAlign(side::Symbol)
    side ∉ [:top, :center, :bottom] && throw("Invalid Valign, $side")
    new(side)
  end
end
Base.convert(::Type{EVAlign}, val::ESymbol) = EVAlign(val.value)
Base.convert(::Type{EVAlign}, val::Symbol) = EVAlign(val)
Base.convert(::Type{EVAlign}, val::ESide) = EVAlign(val.side)
struct EHAlign <: EAlign
  side::Symbol
  function EHAlign(side::Symbol)
    side ∉ [:left, :center, :right] && throw("Invalid Halign, $side")
    new(side)
  end
end
Base.convert(::Type{EHAlign}, val::ESymbol) = EHAlign(val.value)
Base.convert(::Type{EHAlign}, val::Symbol) = EHAlign(val)
Base.convert(::Type{EHAlign}, val::ESide) = EHAlign(val.side)


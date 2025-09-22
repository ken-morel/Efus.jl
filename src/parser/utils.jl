function skip_spaces!(p::EfusParser)::UInt
    m = match(r"^ *", p.text[p.index:end])
    p.index += length(m.match)
    return length(m.match)
end

function ereset(f::Function, p::EfusParser)
    idx = p.index
    r = f()
    if r isa AbstractParseError || isnothing(r)
        p.index = idx
    end
    return r
end

inbounds(p::EfusParser) = length(p.text) >= p.index

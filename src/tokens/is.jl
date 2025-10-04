isindent(c::Char) = c === ' ' || c === '\t'

isnumericstart(c::Char) = isdigit(c) || c ∈ "+-"
isnumericontent(c::Char) = isdigit(c) || isletter(c) || c ∈ "_.+-"

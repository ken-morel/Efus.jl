isindent(c::Char) = c === ' ' || c === '\t'

isnumericstart(c::Char) = isdigit(c) || c === '+' || c === '-'

isnumericontent(c::Char) = isdigit(c) || c === '.' || isletter(c)

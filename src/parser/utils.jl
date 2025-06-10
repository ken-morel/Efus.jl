function nextinline!(parser::Parser, inside::String="<here>")::Union{UInt,AbstractEfusError}
  resetiferror(parser) do
    if parser.index + 1 > length(parser.text)
      SyntaxError("Unexpected end of file", ParserStack(parser, AFTER, inside))
    elseif parser.text[parser.index+1] == '\n'
      SyntaxError("Unexpected end of line", ParserStack(parser, AFTER, inside))
    else
      parser.index += 1
    end
  end
end

function parsesymbol!(parser::Parser)::Union{String,Nothing}
  m::Union{RegexMatch,Nothing} = match(SYMBOL, parser.text, parser.index)
  m === nothing && return nothing
  m.offset != parser.index && return nothing
  parser.index += length(m.match)
  m.match
end

function skipemptylines!(parser::Parser)::Int
  skept = 0
  while true
    if char(parser) == '\n'
      parser.index += 1
      continue
    end
    after = aftercursor(parser)
    if '\n' in after
      pos = findfirst('\n', after)
      if after[begin:pos] ⊆ SPACES
        pos.index += pos + 1
        skept += 1
      else
        break
      end
      continue
    else
      break
    end
  end
  skept
end
function resetiferror(func::Function, parser::Parser)
  start::Int = parser.index
  value = func()
  if iserror(value) || isnothing(value)
    parser.index = start
  end
  value
end

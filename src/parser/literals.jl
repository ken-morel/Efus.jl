function parseesize!(parser::Parser)::Union{ESize,Nothing,AbstractEfusError}
  m = match(ESIZE, parser.text, parser.index)
  if m === nothing || m.offset != parser.index
    return nothing
  end
  parser.index += length(m.match)
  vals = if '.' in m[1] * m[2]
    parse(Float32, m[1]), parse(Float32, m[2])
  else
    parse(Int, m[1]), parse(Int, m[2])
  end
  ESize(vals..., m[3] === nothing ? nothing : Symbol(m[3]))
end
function parseeint!(parser::Parser; checkafter::Bool=true)::Union{EInt,Nothing,AbstractEfusError}
  char(parser) in "+-" || isdigit(char(parser)) || return nothing
  resetiferror(parser) do
    start = parser.index
    if char(parser) in "-+"
      val = nextinline!(parser, "in integer literal")
      iserror(val) && return val
    end
    while true
      if char(parser) == ' '
        break
      elseif !isdigit(char(parser))
        checkafter && return SyntaxError("Unexpected symbols in integer literal", ParserStack(parser, AT, "in integer literal"))
        break
      end
      if iserror(nextinline!(parser))
        parser.index += 1
        break
      end
    end
    EInt(parse(Int, beforecursor(parser)[start:end-1]))
  end
end
function parseedecimal!(parser::Parser)::Union{EDecimal,Nothing,AbstractEfusError}
  char(parser) in "+-" || isdigit(char(parser)) || return nothing
  resetiferror(parser) do
    start = parser.index
    if char(parser) in "-+"
      val = nextinline!(parser, "in decimal literal")
      iserror(val) && return val
    end
    dec = false
    while true
      if char(parser) == '.'
        dec && return SyntaxError("Second decimal point in decimal literal", ParserStack(parser, AT, "in decimal literal"))
        dec = true
      elseif char(parser) == ' '
        break
      elseif !isdigit(char(parser))
        return SyntaxError("Unexpected charater in decimal literal", ParserStack(parser, AT, "in integer literal"))
      end
      if iserror(nextinline!(parser))
        parser.index += 1
        break
      end
    end
    EDecimal(parse(Float32, beforecursor(parser)[start:end]))
  end
end
function parseestring!(parser::Parser)::Union{EString,Nothing,AbstractEfusError}
  char(parser) != '"' && return nothing
  start = parser.index
  while true
    n = nextinline!(parser, "in string literal")
    iserror(n) && return SyntaxError("Unterminated string literal", ParserStack(parser, col(parser, start):col(parser, parser.index), "in string literal"))
    if char(parser) == '\\'
      parser.index += 1
      continue
    elseif char(parser) == '"'
      parser.index += 1
      break
    end
  end
  EString(parser.text[start+1:parser.index-2])
end
function parsekwconstant!(parser::Parser)::Union{EObject,Nothing}
  start = parser.index
  word = parsesymbol!(parser)
  value = if word == "true"
    EBool(true)
  elseif word == "false"
    EBool(false)
  elseif word in ["left", "right", "top", "bottom", "center"]
    ESide(Symbol(word))
  elseif word in ["vertical", "horizontal"]
    EOrient(Symbol(word))
  else
    nothing
  end
  if value === nothing
    parser.index = start
  end
  value
end
function parseeexpr!(parser::Parser, endtoken::Union{String,Nothing}=nothing)::Union{AbstractEfusError,EExpr,Nothing}
  bracketed = endtoken === nothing
  bracketed && char(parser) != '(' && return nothing
  resetiferror(parser) do
    start = parser.index
    count = Int(bracketed)
    while true
      e = nextinline!(parser)
      iserror(e) && return SyntaxError("Unterminated expression", ParserStack(parser, AT, "in expression literal"))
      if char(parser) == '('
        count += 1
      elseif char(parser) == ')'
        count -= 1
        count == 0 && bracketed && break
      elseif !bracketed && startswith(aftercursor(parser), endtoken) && count == 0
        break
      end
    end
    stack = ParserStack(parser, col(parser, start):col(parser), "in efus expr")
    try
      expr = Meta.parse(parser.text[(start+1):(parser.index-1)])
      if bracketed
        parser.index += 1 #skip last bracket
      end
      return EExpr(expr, stack)
    catch exception
      return EJuliaException("Error parsing julia snippet, error following", exception, stack)
    end
  end
end


function parsernamebinding!(parser::Parser)::Union{ENameBinding,Nothing,AbstractEfusError}
  char(parser) == '&' || return nothing
  start = parser.index
  parser.index += 1 #skip '&'
  name = parsesymbol!(parser)
  if name === nothing
    parser.index = start
    return nothing
  end
  ENameBinding(
    Symbol(name),
    ParserStack(parser, col(parser, start):col(parser), "in name binding"),
  )
end



function parsevalue!(parser::Parser)::Union{EObject,Nothing,AbstractEfusError}
  tests = [parsernamebinding!, parseeexpr!, parsekwconstant!, parseesize!, parseedecimal!, parseeint!, parseestring!]
  for test! in tests
    value = test!(parser)
    value === nothing || return value
  end
  nothing
end

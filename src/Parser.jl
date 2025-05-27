export Parser, @efus_str, @efuseval_str

const SYMBOL::Regex = r"\w[\w\d]*"
const SPACES = " \t"
const ESIZE = r"(\d+(?:\.\d+)?)x(\d+(?:\.\d+)?)(\w+)?"

macro efus_str(text::String)
  parse!(Parser(; text=text))
end
macro efuseval_str(text::String)
  code = parse!(Parser(; text=text))
  iserror(code) && return code
  ctx = EvalContext()
  eval!(ctx, code)
end
macro efuseval_str(text::String, mod::String)
  namespace = ModuleNamespace(eval(Symbol(mod)))
  code = parse!(Parser(; text=text))
  iserror(code) && return code
  ctx = EvalContext(namespace)
  eval!(ctx, code)
end


mutable struct Parser
  text::String
  index::UInt
  filename::String
  function Parser(; text::String, file::String="<string>")
    return new(text, 1, file)
  end
end

"""
    beforecursor(parser::Parser)::String
Strips the text before the cursor if index is after end of text.
"""
beforecursor(parser::Parser)::String = parser.text[begin:min(parser.index, length(parser.text))]
beforecursor(parser::Parser, idx::Integer)::String = parser.text[begin:min(idx, length(parser.text))]
aftercursor(parser::Parser)::String = parser.text[min(parser.index, length(parser.text)):end]
aftercursor(parser::Parser, idx::Integer)::String = parser.text[min(idx, length(parser.text)):end]
line(parser::Parser)::Int = 1 + count('\n', beforecursor(parser))
line(parser::Parser, idx::Integer)::Integer = one(idx) + count('\n', beforecursor(parser, idx))
char(parser::Parser)::Union{Char,Nothing} = parser.index <= length(parser.text) ? parser.text[parser.index] : nothing
char(parser::Parser, idx::Integer)::Union{Char,Nothing} = idx <= length(parser.text) ? parser.text[idx] : nothing
function col(parser::Parser)::Int
  text = beforecursor(parser)
  after_last_newline = '\n' in text ? findlast('\n', text) + 1 : 1
  length(text[after_last_newline:end])
end
function col(parser::Parser, idx::Integer)::Int
  text = beforecursor(parser, idx)
  after_last_newline = '\n' in text ? findlast('\n', text) + 1 : 1
  length(text[after_last_newline:end])
end
function skipspaces!(parser::Parser)::Union{Int,Nothing}
  start = parser.index
  while parser.index <= length(parser.text) && char(parser) in SPACES
    parser.index += 1
  end
  parser.index == start && return nothing
  parser.index - start
end
location(parser::Parser)::Tuple{Int,Int} = (line(parser), col(parser))
function ParserStack(parser::Parser, side::LocatedArroundSide, inside::String; add::Int=0)::ParserStack
  parser.index += add
  stack = ParserStack(parser.filename, LocatedArround(side, location(parser)...), getline(parser), inside)
  parser.index -= add
  stack
end
function ParserStack(parser::Parser, range::UnitRange{<:Integer}, inside::String; add::Int=0)::ParserStack
  parser.index += add
  stack = ParserStack(parser.filename, LocatedBetween(line(parser), first(range), last(range)), getline(parser), inside)
  parser.index -= add
  stack
end
function nextinline!(parser::Parser, inside::String="<here>")::Union{Nothing,AbstractError}
  resetiferror(parser) do
    if parser.index + 1 > length(parser.text)
      SyntaxError("Unexpected end of file", ParserStack(parser, AFTER, inside))
    elseif parser.text[parser.index+1] == '\n'
      SyntaxError("Unexpected end of line", ParserStack(parser, AFTER, inside))
    else
      parser.index += 1
      nothing
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
function getline(parser::Parser)::String
  split(parser.text, '\n')[line(parser)]
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

function parse!(parser::Parser)::Union{ECode,Nothing,AbstractError}
  statements = AbstractStatement[]
  while true
    skipemptylines!(parser)
    parser.index > length(parser.text) && break
    parser.text[parser.index:end] ⊆ (SPACES * '\n') && break
    statement = parsestatement!(parser)
    iserror(statement) && return statement
    statement === nothing && return SyntaxError("Unexpected statement", ParserStack(parser, AFTER, "in statement"))
    push!(statements, statement)
  end
  ECode(statements, parser.filename)
end

function parsestatement!(parser::Parser)::Union{AbstractStatement,Nothing,AbstractError}
  resetiferror(parser) do
    tests = [parseusing!, parsetemplatecall!]
    for test! in tests
      value = test!(parser)
      value === nothing || return value
    end
    nothing
  end
end
function parseusing!(parser::Parser)::Union{EUsing,Nothing,AbstractError}
  resetiferror(parser) do
    start = parser.index
    if parsesymbol!(parser) == "using"
      stack = ParserStack(parser, AFTER, "in using statement")
      skipspaces!(parser)
      mod = parsesymbol!(parser)
      skipspaces!(parser)
      mod === nothing && return SyntaxError("Expected module name in using statement", ParserStack(parser, AFTER, "after using keyword"))
      if char(parser) == ':'
        parser.index += 1
        skipspaces!(parser)
        importnames = Symbol[]
        while true
          name = parsesymbol!(parser)
          name === nothing && return SyntaxError("Unexpected tokens in using statement list", ParserStack(parser, AFTER, "in using statement"))
          push!(importnames, Symbol(name))
          skipspaces!(parser)
          char(parser) == '\n' && break
          if char(parser) == ','
            parser.index += 1
            skipspaces!(parser)
          else
            return SyntaxError("Unexpected token in using statement", ParserStack(parser, AT, "in using statement imports list"))
          end
        end
        EUsing(Symbol(mod), importnames, stack, 0)
      else
        EUsing(Symbol(mod), nothing, stack, 0)
      end
    else
      parser.index = start
      nothing
    end
  end
end

function parsetemplatecall!(parser::Parser)::Union{TemplateCall,Nothing,AbstractError}
  resetiferror(parser) do
    indent = skipspaces!(parser)
    stack = ParserStack(
      parser.filename,
      LocatedArround(AFTER, line(parser), col(parser)),
      getline(parser),
      "in template call",
    )
    templatename = parsesymbol!(parser)
    modname = nothing
    templatename === nothing && return nothing
    if char(parser) == '.'
      modname = Symbol(templatename)
      parser.index += 1
      templatename = parsesymbol!(parser)
      templatename === nothing && return SyntaxError("Expected module template name", ParserStack(parser, AT, "in template name"))
    end
    alias = if char(parser) === '&'
      parser.index += 1
      symbol = parsesymbol!(parser)
      symbol === nothing && return SyntaxError(
        "Missing component call alias after '&'",
        combinencloneexceptlocation(stack, LocatedArround(AT, location(parser)...)),
      )
      symbol
    else
      nothing
    end
    skipspaces!(parser)
    parse = parsetemplatecallarguments!(parser)
    if iserror(parse)
      prependstack!(parse, stack)
    else
      TemplateCall(modname, Symbol(templatename), Symbol(alias), parse, indent === nothing ? 0 : indent, stack)
    end
  end
end

function parsetemplatecallarguments!(parser::Parser)::Union{Vector{TemplateCallArgument},Nothing,AbstractError}
  resetiferror(parser) do
    arguments = TemplateCallArgument[]
    while parser.index <= length(parser.text) && char(parser) != '\n'
      next = parsetemplatecallargument!(parser)
      next === nothing && return SyntaxError("Unexpected token in template call arguments", ParserStack(parser, AFTER, "in template call arguments"))
      iserror(next) && return next
      push!(arguments, next)
      skipspaces!(parser)
    end
    arguments
  end
end

function parsetemplatecallargument!(parser::Parser)::Union{TemplateCallArgument,Nothing,AbstractError}
  resetiferror(parser) do
    start = parser.index
    name = parsesymbol!(parser)
    iserror(name) && return name
    name === nothing && return nothing
    char(parser) != '=' && return SyntaxError("Expected equal to sign after template all argument name", ParserStack(parser, AFTER, "after template call argument parameter name"; add=-1))
    parser.index += 1
    value = parsevalue!(parser)
    value === nothing && return SyntaxError("Expected value after equal to sign", ParserStack(parser, AT, "in template call argument key=value pair"))
    iserror(value) && return value
    stack = ParserStack(parser, col(parser, start):col(parser, parser.index - 1), "in template call argument"; add=-1)
    TemplateCallArgument(Symbol(name), value, stack)
  end
end

function resetiferror(func::Function, parser::Parser)
  start::Int = parser.index
  value = func()
  if iserror(value)
    parser.index = start
  end
  value
end
function parseesize!(parser::Parser)::Union{ESize,Nothing,AbstractError}
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
  ESize(vals, m[3] === nothing ? nothing : Symbol(m[3]))
end
function parseeint!(parser::Parser)::Union{EInt,Nothing,AbstractError}
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
        return SyntaxError("Unexpected symbols in integer literal", ParserStack(parser, AT, "in integer literal"))
      end
      if iserror(nextinline!(parser))
        parser.index += 1
        break
      end
    end
    EInt(parse(Int, beforecursor(parser)[start:end]))
  end
end
function parseedecimal!(parser::Parser)::Union{EDecimal,Nothing,AbstractError}
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
function parseestring!(parser::Parser)::Union{EString,Nothing,AbstractError}
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
function parseeexpr!(parser::Parser)::Union{AbstractError,EExpr,Nothing}
  char(parser) != '(' && return nothing
  resetiferror(parser) do
    start = parser.index
    count = 1
    while true
      e = nextinline!(parser)
      iserror(e) && return SyntaxError("Unterminated expression", ParserStack(parser, AT, "in expression literal"))
      if char(parser) == '('
        count += 1
      elseif char(parser) == ')'
        count -= 1
        count == 0 && break
      end
    end
    stack = ParserStack(parser, col(parser, start):col(parser), "in efus expr")
    try
      expr = Meta.parse(parser.text[(start+1):(parser.index-1)])
      parser.index += 1
      return EExpr(expr, stack)
    catch exception
      return EJuliaException("Error parsing julia snippet, error following", exception, stack)
    end
  end
end

function parsevalue!(parser::Parser)::Union{EObject,Nothing,AbstractError}
  tests = [parseeexpr!, parsekwconstant!, parseesize!, parseedecimal!, parseeint!, parseestring!]
  for test! in tests
    value = test!(parser)
    value === nothing || return value
  end
  nothing
end

function parsefile(path::String)::ECode
  parse!(Parser(; file=path))
end


struct SyntaxError <: AbstractError
  message::String
  stacks::Vector{ParserStack}
  SyntaxError(msg::String, stacks::Vector{ParserStack}) = new(msg, stacks)
  SyntaxError(msg::String, stack::ParserStack) = new(msg, ParserStack[stack])
end
struct EJuliaException <: AbstractError
  message::String
  stacks::Vector{ParserStack}
  error::Exception
  EJuliaException(msg::String, err::Exception, stacks::Vector{ParserStack}) = new(msg, stacks, err)
  EJuliaException(msg::String, err::Exception, stack::ParserStack) = new(msg, ParserStack[stack], err)
end
function Base.display(err::EJuliaException)
  println(format(err))
  showerror(stdout, err.error)
end


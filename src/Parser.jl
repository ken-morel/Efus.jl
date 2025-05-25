const SYMBOL::Regex = r"\w[\w\d]*"
const SPACES = " \t"

mutable struct Parser
  text::String
  index::UInt
  filename::String
  function Parser(; file::String)
    open(file) do f
      return new(read(f, String), 1, file)
    end
  end
end

"""
    beforecursor(parser::Parser)::String
Strips the text before the cursor if index is after end of text.
"""
beforecursor(parser::Parser)::String = parser.text[begin:min(parser.index, length(parser.text))]
aftercursor(parser::Parser)::String = parser.text[min(parser.index, length(parser.text)):end]
line(parser::Parser)::Int = 1 + count('\n', beforecursor(parser))
char(parser::Parser)::Union{Char,Nothing} = parser.index <= length(parser.text) ? parser.text[parser.index] : nothing
function col(parser::Parser)::Int
  text = beforecursor(parser)
  last_newline = '\n' in text ? findlast('\n', text) : 1
  length(text[last_newline:end])
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
ParserStack(parser::Parser, side::LocatedArroundSide, inside::String)::ParserStack = ParserStack(parser.filename, LocatedArround(side, location(parser)...), getline(parser), inside)
function ParserStack(parser::Parser, range::UnitRange{<:Integer}, inside::String)::ParserStack
  ParserStack(parser.filename, LocatedBetween(line(parser), first(range), last(range)), getline(parser), inside)
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
  after = findfirst('\n', aftercursor(parser))
  before = findlast('\n', beforecursor(parser))
  strip(parser.text[(before !== nothing ? before : 1):(after !== nothing ? after : length(parser.text))], '\n')
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
    statement = parsenextstatement!(parser)
    iserror(statement) && return statement
    statement === nothing && return SyntaxError("Unexpected statement", ParserStack(parser, AFTER, "in statement"))
    push!(statements, statement)
  end
  ECode(statements, parser.filename)
end

function parsenextstatement!(parser::Parser)::Union{AbstractStatement,Nothing,AbstractError}
  resetiferror(parser) do
    tests = [parsetemplatecall!]
    for test! in tests
      value = test!(parser)
      value === nothing || return value
    end
    nothing
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
    templatename === nothing && return nothing
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
      TemplateCall(Symbol(templatename), Symbol(alias), parse, indent === nothing ? 0 : indent, stack)
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
    name = parsesymbol!(parser)
    iserror(name) && return name
    name === nothing && return nothing
    char(parser) != '=' && return SyntaxError("Expected equal to sign after template all argument name", ParserStack(parser, AFTER, "after template call argument parameter name"))
    parser.index += 1
    value = parsevalue!(parser)
    value === nothing && return SyntaxError("Expected value after equal to sign", ParserStack(parser, AT, "in template call argument key=value pair"))
    iserror(value) && return value
    TemplateCallArgument(Symbol(name), value)
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
function parseestring!(parser::Parser)::Union{EString,Nothing,AbstractError}
  char(parser) != '"' && return nothing
  start = parser.index
  while true
    n = nextinline!(parser, "in string literal")
    iserror(n) && return SyntaxError("Unterminated string literal", ParserStack(parser, start:parser.index+1, "in string literal"))
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


function parsevalue!(parser::Parser)::Union{EObject,Nothing,AbstractError}
  tests = [parseeint!, parseestring!]
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
getstacks(e::SyntaxError) = e.stacks
function prependstack!(e::SyntaxError, stack::ParserStack)::SyntaxError
  pushfirst!(e.stacks, stack)
  e
end
function format(error::SyntaxError)::String
  stacktrace = join(format.(getstacks(error)) .* "\n")
  message = String(nameof(typeof(error))) * ": " * error.message
  stacktrace * message
end

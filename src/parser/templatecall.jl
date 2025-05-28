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

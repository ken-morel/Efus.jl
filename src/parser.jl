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


include("parser/parser.jl")

include("parser/fragments.jl")

include("parser/utils.jl")

include("parser/statements.jl")

include("parser/templatecall.jl")

include("parser/literals.jl")

include("parser/exceptions.jl")



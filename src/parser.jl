export Parser, @efus_str, @efuseval_str


const SYMBOL::Regex = r"\w[\w\d]*"
const SPACES = " \t"
const ESIZE = r"(\d+(?:\.\d+)?)x(\d+(?:\.\d+)?)(\w+)?"

macro efus_str(text::String)
  parse!(Parser(; text=text))
end
macro efusthrow_str(text::String)
  val = parse!(Parser(; text=text))
  if iserror(val)
    display(val)
    throw("error $val")
  end
  val
end
macro efuspreeval_str(text::String)
  code = parse!(Parser(; text=text))
  iserror(code) && return code
  ctx = EfusEvalContext()
  eval!(ctx, code)
end
macro efuseval_str(text::String)
  code = parse!(Parser(; text=text))
  iserror(code) && return code
  :(
    eval!($(EfusEvalContext()), $code)
  )
end
macro efuspreeval_str(text::String, mod::String)
  namespace = ModuleNamespace(Base.eval(Symbol(mod)))
  code = parse!(Parser(; text=text))
  iserror(code) && return code
  ctx = EfusEvalContext(namespace)
  eval!(ctx, code)
end
macro efuseval_str(text::String, mod::String)
  namespace = ModuleNamespace(Base.eval(Symbol(mod)))
  code = parse!(Parser(; text=text))
  println("Running before time")
  iserror(code) && return code
  :(
    println("Running after time");
    eval!($(EfusEvalContext(namespace)), $code)
  )
end


include("parser/parser.jl")

include("parser/fragments.jl")

include("parser/utils.jl")

include("parser/statements.jl")

include("parser/templatecall.jl")

include("parser/literals.jl")

include("parser/exceptions.jl")

include("parser/comment.jl")

include("parser/ejlblock.jl")

include("src/Efus.jl")

using .Efus: parsefile, eval!, EvalContext, Namespace, Template, TemplateBackend, TemplateParameter
using .Efus: AbstractError

win = Template("Window", TemplateBackend(), TemplateParameter[])

code = parsefile("test.efus")
if typeof(code) <: AbstractError
  display(code)
else
  ctx = EvalContext(Namespace(), [])
  comp = eval!(ctx, code)
  if typeof(comp) <: AbstractError
    display(comp)
  else

    println(comp)
  end
end


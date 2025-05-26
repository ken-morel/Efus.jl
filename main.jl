include("src/Efus.jl")

using .Efus: parsefile, Template, TemplateParameter, TemplateBackend, AbstractError, EvalContext, eval!, Namespace, addtemplate!, EString, EInt, AbstractMount, mount!
namespace = Namespace()

using Gtk4

struct Window <: AbstractMount
  win::GtkWindow
end

addtemplate!(namespace, Template(
  :Window,
  TemplateBackend(
    mount=function (component)
      component.mount = Window(GtkWindow(component[:title]))
    end,
    unmount=function (component)
    end
  ),
  TemplateParameter[
    :title=>EString
  ],
))

# addtemplate!(namespace, Template(
#   :Label,
#   TemplateBackend(),
#   TemplateParameter[
#     :text=>EString
#   ],
# ))

code = parsefile("test.efus")
if typeof(code) <: AbstractError
  display(code)
else
  ctx = EvalContext(namespace, [])
  comp = eval!(ctx, code)
  if typeof(comp) <: AbstractError
    display(comp)
  else
    println(comp)
    mount!(comp)
  end
end


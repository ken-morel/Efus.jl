include("src/Efus.jl")
println("Starting to run")


module Gtk
using ..Efus: Efus, AbstractMount, AbstractError, TemplateBackend, Component, Template, TemplateParameter, EString, EDecimal, ESize
using Gtk4

@kwdef struct GtkMount <: AbstractMount
  widget::Any #TODO: specialize this when Gtk functional
end
@kwdef struct GtkBackend <: TemplateBackend
  mounter::Function
end

function Efus.mount!(backend::GtkBackend, comp::Component)::GtkMount
  backend.mounter(comp)
end

templates = [
  Template(
    :Window,
    GtkBackend(
      mounter=function (component)
        size = component[:size].value
        component.mount = GtkMount(GtkWindow(component[:title], size...))
      end,
    ),
    TemplateParameter[
      :title => EString
      :size => ESize{Int,:px} => ESize((500, 300), :px)
    ],
  ),
]
Efus.registertemplatemodule(:Gtk, templates)
end
# addtemplate!(namespace, Template(
#   :Label,
#   TemplateBackend(),
#   TemplateParameter[
#     :text=>EString
#   ],
# ))
using .Gtk

using .Efus: @efuseval_str, AbstractError, EvalContext, eval!, mount!

component = efuseval"""
using Gtk: Window

Window title="I love" size=500x300px
"""
if typeof(component) <: AbstractError
  display(component)
else
  println(component)
  mount!(component)
end


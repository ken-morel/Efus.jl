include("src/Efus.jl")
println("Starting to run")


module Gtk
using ..Efus: Efus, AbstractMount, AbstractError, TemplateBackend, Component, Template, TemplateParameter, EString
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
        component.mount = GtkMount(GtkWindow(component[:title]))
      end,
    ),
    TemplateParameter[
      :title=>EString
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

Window title="Hello world
"""
if typeof(component) <: AbstractError
  display(component)
else
  println(component)
  mount!(component)
end


abstract type AbstractMount end
@kwdef struct TemplateBackend
  mount::Function
  unmount::Function
  update::Function = function (_) end
end



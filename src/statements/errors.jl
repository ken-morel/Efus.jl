struct NameError <: AbstractError
  message::String
  stacks::Vector{ParserStack}
  name::Symbol
  namespace::AbstractNamespace #AbstractNamespace
  NameError(msg::String, name::Symbol, namespace::AbstractNamespace, stacks::Vector{ParserStack}) = new(msg, stacks, name, namespace)
  NameError(msg::String, name::Symbol, namespace::AbstractNamespace, stack::ParserStack) = new(msg, ParserStack[stack], name, namespace)
end

struct ImportError <: AbstractError
  message::String
  stacks::Vector{ParserStack}
  ImportError(msg::String, stacks::Vector{ParserStack}) = new(msg, stacks)
  ImportError(msg::String, stack::ParserStack) = new(msg, ParserStack[stack])
end

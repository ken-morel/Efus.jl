struct SyntaxError <: AbstractEfusError
  message::String
  stacks::Vector{ParserStack}
  SyntaxError(msg::String, stacks::Vector{ParserStack}) = new(msg, stacks)
  SyntaxError(msg::String, stack::ParserStack) = new(msg, ParserStack[stack])
end
struct EJuliaException <: AbstractEfusError
  message::String
  stacks::Vector{ParserStack}
  error::Exception
  EJuliaException(msg::String, err::Exception, stacks::Vector{ParserStack}) = new(msg, stacks, err)
  EJuliaException(msg::String, err::Exception, stack::ParserStack) = new(msg, ParserStack[stack], err)
end
function Base.display(err::EJuliaException)
  println(format(err))
  showerror(stdout, err.error)
end

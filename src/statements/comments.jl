struct EComment <: AbstractStatement
  text::String
  stack::ParserStack
end

function eval!(::EvalContext, ::EComment)
end

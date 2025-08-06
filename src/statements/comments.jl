struct EComment <: AbstractStatement
    text::String
    stack::ParserStack
end

function eval!(::EfusEvalContext, ::EComment)
end

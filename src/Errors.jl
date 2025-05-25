abstract type AbstractError <: EObject end
Base.display(error::AbstractError) = println(format(error))

abstract type AbstractFileLocation end
@enum LocatedArroundSide BEFORE AFTER AT


iserror(e::Any) = typeof(e) <: AbstractError
struct ParserStack
  file::String
  location::AbstractFileLocation
  line::String
  inside::String
  ParserStack(file::String, location::AbstractFileLocation, line::String, inside::String) = new(file, location, line, inside)
end
combinencloneexceptlocation(a::ParserStack, b::AbstractFileLocation)::Vector{ParserStack} = Vector{ParserStack}([a, ParserStack(a.file, b, a.line, a.inside)])
function format(stack::ParserStack)::String
  location = format(stack.location) * " inside " * stack.file * " " * stack.inside
  sample = styleunderline(stack.location, stack.line)
  location * ":\n" * sample
end




struct LocatedArround <: AbstractFileLocation
  direction::LocatedArroundSide
  line::Int
  col::Int
end
function styleunderline(location::LocatedArround, line::String)::String
  character::Char = location.direction == BEFORE ? '<' : location.direction == AT ? '^' : location.direction == AFTER ? '>' : '@'
  underline = " "^(location.col - 1) * character
  line * "\n" * underline
end
function format(loc::LocatedArround)::String
  where_ = (uppercasefirst ∘ lowercase ∘ String ∘ Symbol)(loc.direction)
  pos = "line $(loc.line), column $(loc.col)"
  where_ * " " * pos
end


struct LocatedBetween <: AbstractFileLocation
  line::Int
  from::Int
  to::Int
end
format(loc::LocatedBetween)::String = "line $(loc.line), between column $(loc.from) and $(loc.to)"
function styleunderline(location::LocatedBetween, line::String)::String
  underline = " "^(location.from - 1) * "~"^(location.to - location.from)
  line * "\n" * underline
end

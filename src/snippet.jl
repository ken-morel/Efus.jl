export Snippet

struct Snippet <: Function
    fn::Function
end

(s::Snippet)(args...; kw...) = s.fn(args..., kw...)

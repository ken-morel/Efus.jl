struct Snippet{T <: NamedTuple}
    fn::Function
end

# I hope kwargs are internally represented as NamedTuple
(sn::Snippet)(args...) = sn.fn(args...)

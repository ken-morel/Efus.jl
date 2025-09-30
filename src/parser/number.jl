const NUMERIC = r"(-|\+)?([\d_]+)(\.[\d_]*)([eE]\d+)?((?:\p{L}|_)(?:\p{L}|\p{N}|_)*)?"

function parse_number!(p::EfusParser)::Union{Ast.Numeric, Nothing}
    return ereset(p) do
        number = match(NUMERIC, p.text, p.index)
        if !isnothing(number) && number.offset == p.index
            p.index += length(number.match)
            return Ast.Numeric(Meta.parse(number.match))
        end
    end
end

const EXPRQUOTE = r"\"|'"
const BRACKET = r"\(|\)"
const MARKEDREACTANT = r"(?<!')(\p{L}|_)(\p{L}|\p{N}|_)*'"

function parse_juliaexpression!(p::EfusParser)::Union{Ast.Expression, Ast.LiteralValue, AbstractParseError, Nothing}
    return ereset(p) do
        start = current_char(p)
        name = parse_symbol!(p)
        if !isnothing(name)
            if inbounds(p) && p.text[p.index] == '''
                pos = (1, p.index) .|> UInt
                p.index += 1
                @zig! eoe(p)
                return Ast.Expression(string(name) * "'", Dict(name => [pos]))
            else
                @zig! eoe(p)

                !isnothing(name) && return Ast.Expression(string(name), Dict())
            end
        end

        if p.text[p.index] == ':'
            p.index += 1
            name = parse_symbol!(p)
            isnothing(name) && return EfusSyntaxError("Invalid julia Symbol at pos", start * current_char(p))
            return Ast.LiteralValue(name)
        elseif p.text[p.index] == '('
            count = 1
            p.index += 1
            exprstart = p.index
            !inbounds(p) && return EfusSyntaxError("EOF Before literal expression at ", current_char(p, -1))
            exprstart = p.index
            while inbounds(p)
                nextbracket = let m = match(BRACKET, p.text, p.index)
                    if !isnothing(m)
                        m.offset
                    end
                end
                nextquote = findnext('"', p.text, p.index)
                isnothing(nextbracket)&&return EfusSyntaxError("Unterminated julia expression stated here", start)
                if isnothing(nextquote) || nextbracket < nextquote
                    p.index = nextbracket + 1
                    count += p.text[nextbracket] == '(' ? 1 : -1
                else
                    p.index = nextquote
                    @zig! parse_string!(p)
                end
                count == 0 && break
            end
            exprstop = p.index - 2
            p.index = exprstart
            expr = @zig! parse_reactiveexpression(p, exprstop)
            p.index = exprstop + 2
            return expr
        end
    end
end

function eoe(p::EfusParser)
    return if inbounds(p) && !isspace(p.text[p.index])
        EfusSyntaxError("Unexpected token after end of expression", current_char(p))
    end
end


function parse_reactiveexpression(p::EfusParser, stop::UInt)::Union{Ast.Expression, AbstractParseError}
    return ereset(p) do
        beginning = p.index
        reactants = Dict{Symbol, Vector{NTuple{2, UInt}}}()
        while p.index <= stop
            str = findfirst(==('"'), p.text[p.index:end])
            str = if !isnothing(str) && str <= stop
                str + p.index - 1
            end
            reactant = match(MARKEDREACTANT, p.text, p.index)
            if !isnothing(reactant) && reactant.offset > stop
                reactant = nothing
            end
            isnothing(reactant) && break
            if !isnothing(str) && reactant.offset > str
                p.index = str
                @zig! parse_string!(p)
                if p.index > stop
                    p.index = stop
                    return EfusSyntaxError("Unterminated string inside reactive expression", current_char(p))
                end
            else
                start = reactant.offset
                last = start + length(reactant.match)
                p.index = nextind(p.text, last)
                key = Symbol(p.text[start:(last - 2)])
                if key ∉ keys(reactants)
                    reactants[key] = []
                end
                push!(reactants[key], (start + 1, last) .- beginning)
            end
        end
        return Ast.Expression(p.text[beginning:stop], reactants)
    end
end

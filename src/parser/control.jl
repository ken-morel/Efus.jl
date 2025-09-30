const OPENING_CONTROLS = [:if, :for, :do, :begin]


function parse_controlflow!(p::EfusParser)::Union{Ast.ControlFlow, AbstractParseError, Nothing}
    @zig! check_unbound_flows(p)
    flow = @zig! parse_ifstatement!(p)
    !isnothing(flow) && return flow
    flow = @zig! parse_forstatement!(p)
    !isnothing(flow) && return flow
    return
end

function check_unbound_flows(p::EfusParser)::Union{AbstractParseError, Nothing}
    origin = p.index
    skip_spaces!(p)
    b = current_char(p)
    s = parse_symbol!(p)
    e = current_char(p, -1)
    p.index = origin
    return if s ∈ (:end, :else, :elseif)
        EfusSyntaxError("Unexpected $s at position", e)
    end
end

function parse_ifstatement!(p::EfusParser)::Union{Ast.IfStatement, AbstractParseError, Nothing}
    return ereset(p) do
        b = current_char(p)
        parse_symbol!(p) != :if && return nothing
        e = current_char(p, -1)
        lastcontrol = b * e
        branches = Ast.IfBranch[]
        (condition,) = @zig! parse_jlexpressiontilltoken!(p, r"\n")
        name = :if
        while true
            incodestart = p.index
            value = skip_toblock!(p, [:elseif, :else, :end])
            isnothing(value) && return EfusSyntaxError(
                "Non terminated control flow after here",
                lastcontrol
            )
            code, name, lastcontrol = value

            line = lastcontrol.start[1]
            block = @zig! subparse!(p, code, "in $name block at line $line", incodestart)
            push!(branches, Ast.IfBranch(condition, block))
            if name == :elseif
                (condition,) = @zig! parse_jlexpressiontilltoken!(p, r"\n")
            elseif name == :else
                condition = nothing
            elseif name == :end
                break
            end

        end
        return Ast.IfStatement(; branches)
    end
end

function parse_forstatement!(p::EfusParser)::Union{Ast.ForStatement, Nothing}
    return ereset(p) do
        b = current_char(p)
        parse_symbol!(p) != :for && return nothing
        e = current_char(p, -1)

        forloc = b * e

        (dest,) = @zig! parse_jlexpressiontilltoken!(p, r"in|∈|\=")
        (iter,) = @zig! parse_jlexpressiontilltoken!(p, r"\n")

        codestart = p.index
        code = @zig! skip_toblock!(p, [:end, :else])
        isnothing(code) && return EfusSyntaxError(
            "Missing `end` or `else` after for",
            forloc
        )
        (code, name, loc) = code
        forcontent = @zig! subparse!(p, code, "in for loop at line $(forloc.start[1])", codestart)
        elsecontent = if name == :else
            codestart = p.index
            elsecode = @zig! skip_toblock!(p, [:end])
            isnothing(elsecode) && return EfusSyntaxError(
                "Missing `end` after for statement else",
                loc
            )
            @zig! subparse!(p, elsecode[1], "in for loop else at line $(loc.start[1])", codestart)
        end
        return Ast.ForStatement(; iterator = iter, item = dest, block = forcontent, elseblock = elsecontent)
    end
end

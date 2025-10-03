macro next(ts, at = "")
    name = gensym()
    loc = gensym()
    return quote
        let $loc = loc($ts), $name = next!($ts)
            isnothing($name) && return token(
                ERROR,
                "Unexpected EOF " * $at,
                Location($loc, $loc, $ts.file)
            )
            $name
        end

    end
end

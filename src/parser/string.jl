function parse_string!(p::EfusParser)::Union{AbstractParseError, Nothing, Ast.LiteralValue}
    return ereset(p) do
        !inbounds(p) && return nothing

        start_char = p.text[p.index]
        start_loc = current_char(p)

        if start_char != ''' && start_char != '"'
            return nothing
        end

        p.index += 1

        if start_char == '''
            char_val::Char = if !inbounds(p)
                return EfusSyntaxError("Unterminated empty character literal", start_loc)
            elseif p.text[p.index] == '\''
                p.index += 1
                !inbounds(p) && return EfusSyntaxError("Unterminated character literal", start_loc * current_char(p))
                c = p.text[p.index]
                p.index += 1
                c == 'n' ? '\n' : \
                c == 't' ? '\t' : \
                c == 'r' ? '\r' : \
                c == '\\' ? '\\' : \
                c == ''' ? '\'' : \
                return EfusSyntaxError("Invalid character escape sequence", current_char(p, -1) * current_char(p))
            else
                c = p.text[p.index]
                p.index += 1
                c
            end

            if !inbounds(p) || p.text[p.index] != '''
                return EfusSyntaxError("Character literal must be enclosed in single quotes and contain only one character", start_loc * current_char(p))
            end
            p.index += 1
            return Ast.LiteralValue(char_val)
        end

        if start_char == '"'
            content = IOBuffer()
            while true
                if !inbounds(p)
                    return EfusSyntaxError("Unterminated string literal", start_loc * current_char(p))
                end

                char = p.text[p.index]

                if char == '"'
                    p.index += 1
                    break
                elseif char == '\''
                    p.index += 1
                    if !inbounds(p)
                        return EfusSyntaxError("Unterminated string literal after escape", start_loc * current_char(p))
                    end
                    escape_loc = current_char(p, -1) * current_char(p)
                    escaped_char = p.text[p.index]
                    p.index += 1
                    if escaped_char == 'n'
                        write(content, '\n')
                    elseif escaped_char == 't'
                        write(content, '\t')
                    elseif escaped_char == 'r'
                        write(content, '\r')
                    elseif escaped_char == '\\'
                        write(content, '\\')
                    elseif escaped_char == '"'
                        write(content, '"')
                    else
                        return EfusSyntaxError("Invalid string escape sequence: $(escaped_char)", escape_loc)
                    end
                else
                    p.index += 1
                    write(content, char)
                end
            end
            return Ast.LiteralValue(String(take!(content)))
        end

        return nothing
    end
end

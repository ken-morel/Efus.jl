export @efus

macro efus(code::String)
    parser = Parser.EfusParser(code, "<string>")
    return @time Parser.try_parse!(parser)
end

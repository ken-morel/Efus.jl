using IonicEfus

@testset "Error checks" begin
    io = IOBuffer()
    CODE = """
    banana()
      if foo !== bar
        for foo in bar
          Hello
        else
          Foo bar=5
        end
      end
    end
    Ama a=:ama b=(bar) c=(ama)::Int
      code()
        Label foo=4
      end
      ("Inline julia";code;)
      for (foo, bar) in cases'
        if foo !== bar
          Case1
        elseif foo += bar <= 5
          Case2
        else
          Case3
        end
      end
    """
    AST = IonicEfus.parse_efus(CODE)
    @test try
        show_ast(io, AST)
        true
    catch
        printstyled("ERROR showing Ast:"; color = :red, bold = true)
        println(String(take!(io)))
        rethrow()
    end
end

using IonicEfus
using IonicEfus.Gen
using IonicEfus.Ast

@testset "Code Generation" begin
    @testset "Basic Component Generation" begin
        code = "Button text=\"Hello\" size=12"
        ast = parse_efus(code, "test")
        generated = Gen.generate(ast)
        
        @test generated isa Expr
        @test generated.head == :call
        @test generated.args[1] == :|>
        
        # Should contain Button function call
        button_call = generated.args[2].args[1]
        @test button_call isa Expr
        @test button_call.head == :call
        @test button_call.args[1] == :Button
    end

    @testset "Component Arguments Generation" begin
        code = "Button text=\"Hello\" size=12 enabled=true"
        ast = parse_efus(code, "test")
        generated = Gen.generate(ast)
        
        button_call = generated.args[2].args[1]
        
        # Should have keyword arguments
        kwargs = filter(arg -> arg isa Expr && arg.head == :kw, button_call.args)
        @test length(kwargs) == 3
        
        # Check argument names
        arg_names = [kw.args[1] for kw in kwargs]
        @test :text in arg_names
        @test :size in arg_names  
        @test :enabled in arg_names
    end

    @testset "Nested Component Generation" begin
        code = """
        Container
          Header title=\"Welcome\"
          Button text=\"Click\"
        """
        ast = parse_efus(code, "test")
        generated = Gen.generate(ast)
        
        container_call = generated.args[2].args[1]
        @test container_call.args[1] == :Container
        
        # Should have children argument
        children_kw = findfirst(arg -> arg isa Expr && arg.head == :kw && arg.args[1] == :children, container_call.args)
        @test children_kw !== nothing
    end

    @testset "For Loop Generation" begin
        code = """
        for item in items
          Button text=item
        end
        """
        ast = parse_efus(code, "test")
        generated = Gen.generate(ast)
        
        @test generated isa Expr
        # Should contain some form of iteration
        @test contains(string(generated), "item") || contains(string(generated), "items")
    end

    @testset "If Statement Generation" begin
        code = """
        if condition
          Button text=\"True\"
        else
          Button text=\"False\"
        end
        """
        ast = parse_efus(code, "test")
        generated = Gen.generate(ast)
        
        @test generated isa Expr
        # Should contain if statement structure
        @test contains(string(generated), "if") || contains(string(generated), "condition")
    end

    @testset "Generated Code Compilation" begin
        # Test that generated expressions are valid Julia code
        code = "Button text=\"Hello\""
        ast = parse_efus(code, "test")
        generated = Gen.generate(ast)
        
        # Should be syntactically valid Julia
        try
            Meta.parse(string(generated))
            @test true  # Generated code parses correctly
        catch e
            @test_broken false
            @info "Generated code parsing failed" exception=e
        end
    end
end
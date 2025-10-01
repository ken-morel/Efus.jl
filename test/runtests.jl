using Efus
using Test

@testset "Efus.jl" begin

    @testset "Component Calls" begin
        @testset "Basic component call" begin
            generated_code = Efus.codegen_string("MyComponent")
            @test occursin("MyComponent", generated_code)
        end

        @testset "Component with simple arguments" begin
            generated_code = Efus.codegen_string("MyComponent text=\"Hello\" number=123")
            @test occursin("text = \"Hello\"", generated_code)
            @test occursin("number = 123", generated_code)
        end

        @testset "Component with splat arguments" begin
            generated_code = Efus.codegen_string("MyComponent args...")
            @test occursin("args...", generated_code)
        end

        @testset "Component with children" begin
            generated_code = Efus.codegen_string(
                """
                MyComponent
                  AnotherComponent
                """
            )
            @test occursin("MyComponent", generated_code)
            @test occursin("AnotherComponent", generated_code)
        end
    end

    @testset "Control Flow" begin
        @testset "If statement" begin
            generated_code = Efus.codegen_string(
                """
                if a > b
                  Label text="a is greater"
                end
                """
            )
            @test occursin("a > b", generated_code)
            @test occursin("Label", generated_code)
        end

        @testset "If-else statement" begin
            generated_code = Efus.codegen_string(
                """
                if a > b
                  Label text="a is greater"
                else
                  Label text="b is greater or equal"
                end
                """
            )
            @test occursin("a > b", generated_code)
            @test occursin("else", generated_code)
        end

        @testset "If-elseif-else statement" begin
            generated_code = Efus.codegen_string(
                """
                if a > b
                  Label text="a is greater"
                elseif a < b
                  Label text="a is smaller"
                else
                  Label text="a is equal to b"
                end
                """
            )
            @test occursin("a < b", generated_code)
            @test occursin("end", generated_code)
            @test occursin("else", generated_code)
        end

        @testset "For loop" begin
            generated_code = Efus.codegen_string(
                """
                for i in 1:10
                  Label text=(i)
                end
                """
            )
            @test occursin("for", generated_code)
        end

        @testset "For-else loop" begin
            generated_code = Efus.codegen_string(
                """
                for i in []
                  Label text=(i)
                else
                  Label text="Empty"
                end
                """
            )
            @test occursin("else", generated_code)
        end
    end

    @testset "Data Types" begin
        @testset "Numbers" begin
            generated_code = Efus.codegen_string("Comp value=123")
            @test occursin("123", generated_code)
            generated_code = Efus.codegen_string("Comp value=-1.5e-2")
            @test occursin("-0.015", generated_code)
        end

        @testset "Strings" begin
            try
                generated_code = Efus.codegen_string("Comp text=\"Hello, \"world\"!\" ")
            catch e
            else
                error("Should fail due to unescaped quotes")
            end
        end

        @testset "Symbols" begin
            generated_code = Efus.codegen_string("Comp value=:my_symbol")
            @test occursin("my_symbol", generated_code)
        end

        @testset "Vectors" begin
            generated_code = Efus.codegen_string("Comp value=[1, \"two\", :three]")
            @test occursin("[1", generated_code)
            @test occursin("]", generated_code)
            @test occursin("three", generated_code)
        end
    end

    @testset "Reactivity" begin
        @testset "Reactive variable" begin
            generated_code = Efus.codegen_string("Comp value=my_var'")
            @test occursin("getvalue(my_var)", generated_code)
        end
        @testset "Reactive assigning" begin
            generated_code = Efus.codegen_string("Comp value=(my_var' = 5; my_var')")
            @test occursin("setvalue!(my_var", generated_code)
        end
    end

    @testset "Blocks" begin
        @testset "Begin block" begin
            generated_code = Efus.codegen_string(
                """
                MyComponent value=|
                  begin
                    Label text="Calculating..." snippet=|
                      do
                        Banana
                      end c=4 text=|
                        "Hello world"
                  end
                """
            )
            @test occursin("FunctionWrapper", generated_code)
            @test occursin("value", generated_code)
        end

        @testset "Julia block" begin
            generated_code = Efus.codegen_string("MyComponent value=(1 + 2)")
            @test occursin("1 + 2", generated_code)
        end

        @testset "Snippets" begin
            @testset "Snippet with parameters" begin
                generated_code = Efus.codegen_string(
                    """
                    MyComponent code=|
                      do item::Int
                        Label text=(item)
                      end
                    """
                )
                @test occursin("item::Int", generated_code)
            end
        end
    end

    # Original test case
    @testset "Component with padding and button" begin
        generated_code = Efus.codegen_string(
            """
            Label padding=[
              (d' = c' * ama';d' / 4),
              do c::Int
                Button text=ama
              end,
              (ama', 4)
            ]
            """, true
        )
        @test generated_code isa String
    end
end


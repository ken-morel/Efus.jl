using Efus
using Test

@testset "Efus.jl" begin

    @testset "Component Calls" begin
        @test Efus.codegen_string("MyComponent") isa String
    end

    @testset "Component with complex arguments" begin
        @test Efus.codegen_string("MyComponent text=\"Hello\" number=123 flag=true") isa String
    end

    @testset "Component with splat arguments" begin
        @test Efus.codegen_string("MyComponent args...") isa String
    end

    @testset "Deeply nested components" begin
        @test Efus.codegen_string(
            """
            Panel
              Column
                Row
                  Button text=\"Click Me\"
            """
        ) isa String
    end
end

@testset "Control Flow" begin
    @testset "Nested if-else in for loop" begin
        @test Efus.codegen_string(
            """
            for item in items'
              if item.type == :A
                ComponentA data=item
              else
                ComponentB data=item
              end
            end
            """
        ) isa String
    end

    @testset "For-else loop" begin
        @test Efus.codegen_string(
            """
            for i in []
              Label text=(i)
            else
              Label text=\"Empty\"
            end
            """
        ) isa String
    end
end

@testset "Data Types and Reactivity" begin
    @testset "Complex vector with reactive elements" begin
        @test Efus.codegen_string("Comp value=[1, (a' + b'), :symbol, [c', d']]") isa String
    end

    @testset "Reactive assignment and usage" begin
        @test Efus.codegen_string("Comp value=(my_var' = 5; my_var' * 2)") isa String
    end
end

@testset "Blocks and Snippets" begin
    @testset "Component with complex begin block" begin
        @test Efus.codegen_string(
            """
            MyComponent value=begin
              calculate_something a=(a', b')
              if x > 10
                Label x=:big
              else
                Label c=:small
              end
            end
            """
        ) isa String
    end

    @testset "Snippet with multiple parameters" begin
        @test Efus.codegen_string(
            """
            MyComponent c=|
              do item::String, index::Int
                Label text=(index + \": \" + item)
              end
            """
        ) isa String
    end
end

@testset "Original complex test case" begin
    @test Efus.codegen_string(
        """
        Label padding=[
          (d' = c' * ama';d' / 4),
          do c::Int
            Button text=ama
          end,
          (ama', 4)
        ]
        """, true
    ) isa String
end

@testset "Invalid Syntax" begin
    @testset "Unterminated if" begin
        @test_throws Efus.EfusError Efus.codegen_string(
            """
            if a > b
              Label text=\"Missing end\"
            """
        )
    end

    @testset "Unterminated for" begin
        @test_throws Efus.EfusError Efus.codegen_string(
            """
            for i in 1:10
              Label text=(i)
            """
        )
    end

    @testset "Unterminated do block" begin
        @test_throws Efus.EfusError Efus.codegen_string(
            """
            MyComponent val=|
              do
                Label
            """
        )
    end

    @testset "Invalid component argument" begin
        @test_throws Efus.EfusError Efus.codegen_string("MyComponent text=")
        @test_throws Efus.EfusError Efus.codegen_string("MyComponent =value")
    end

    @testset "Unmatched brackets in vector" begin
        @test_throws Efus.EfusError Efus.codegen_string("MyComponent value=[1, 2, (a + b]")
    end

    @testset "Unexpected 'else'" begin
        @test_throws Efus.EfusError Efus.codegen_string(
            """
            else
              Label text=\"misplaced else\"
            end
            """
        )
    end

    @testset "Unescaped quotes in string" begin
        @test_throws Efus.EfusError Efus.codegen_string("Comp text=\"Hello, \"world\"!\"")
    end
end


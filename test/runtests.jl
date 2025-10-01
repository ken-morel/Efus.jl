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
@testset "Reactivity System (Unit Tests)" begin
    @testset "Reactant" begin
        r = Efus.Reactant(10)
        @test Efus.getvalue(r) == 10
        Efus.setvalue!(r, 20)
        @test Efus.getvalue(r) == 20
    end

    @testset "Catalyst and Reactions" begin
        r = Efus.Reactant(5)
        c = Efus.Catalyst()
        triggered_value = 0

        reaction_fn = (reactant) -> triggered_value = Efus.getvalue(reactant)

        reaction = Efus.catalyze!(c, r, reaction_fn)

        Efus.setvalue!(r, 15)
        @test triggered_value == 15

        # Test inhibit!
        Efus.inhibit!(reaction)
        Efus.setvalue!(r, 25)
        @test triggered_value == 15 # Should not have changed

        # Test denature!
        Efus.catalyze!(c, r, reaction_fn)
        Efus.setvalue!(r, 35)
        @test triggered_value == 35
        Efus.denature!(c)
        Efus.setvalue!(r, 45)
        @test triggered_value == 35 # Should not have changed
    end

    @testset "Reactor" begin
        a = Efus.Reactant(10)
        b = Efus.Reactant(20)

        # Create a reactor that sums a and b
        sum_reactor = Efus.Reactor(Int, () -> Efus.getvalue(a) + Efus.getvalue(b), nothing, [a, b])

        @test Efus.getvalue(sum_reactor) == 30

        Efus.setvalue!(a, 15)
        @test Efus.isfouled(sum_reactor) == true
        @test Efus.getvalue(sum_reactor) == 35
        @test Efus.isfouled(sum_reactor) == false

        Efus.setvalue!(b, 25)
        @test Efus.isfouled(sum_reactor) == true
        @test Efus.getvalue(sum_reactor) == 40
        @test Efus.isfouled(sum_reactor) == false
    end
end
@testset "Ast display" begin
    show(
        stdout, MIME("text/plain"), Efus.try_parse(
            """
            LabelFrame padding=(3.5, 4) label=|
              do frm::LabelFrame
                Label text="Hello world" justify=c
              end
              Box orient=:h
                Label text=("Your name(" * valid' * "): ")
                Input var=name placeholder=name'
                Button text="Clear" onclick=(() -> name' = "")
                """
        )
    )
end
@testset "Macros (@reactor and @radical)" begin
    @testset "@reactor (Lazy Evaluation)" begin
        a = Efus.Reactant(10)
        b = Efus.Reactant(20)

        # Assumes Ionic.translate is available and works
        # We are testing the macro expansion here
        lazy_reactor = @reactor a' + b'

        @test lazy_reactor isa Efus.Reactor{Int}
        @test Efus.getvalue(lazy_reactor) == 30
        @test !Efus.isfouled(lazy_reactor)

        Efus.setvalue!(a, 15)

        # Should be fouled, but value should not have updated yet
        @test Efus.isfouled(lazy_reactor)
        @test lazy_reactor.value == 30

        # Now, getvalue should trigger the update
        @test Efus.getvalue(lazy_reactor) == 35
        @test !Efus.isfouled(lazy_reactor)
    end

    @testset "@radical (Eager Evaluation)" begin
        a = Efus.Reactant(10)
        b = Efus.Reactant(20)

        eager_reactor = @radical a' + b'

        @test eager_reactor isa Efus.Reactor{Int}
        @test Efus.getvalue(eager_reactor) == 30
        @test !Efus.isfouled(eager_reactor)

        Efus.setvalue!(a, 15)

        # Should have re-computed immediately
        @test !Efus.isfouled(eager_reactor)
        @test Efus.getvalue(eager_reactor) == 35
    end

    @testset "Type Inference" begin
        s1 = Efus.Reactant("Hello")
        s2 = Efus.Reactant(", world!")
        str_reactor = @reactor s1' * s2'
        @test str_reactor isa Efus.Reactor{String}
        @test Efus.getvalue(str_reactor) == "Hello, world!"

        f1 = Efus.Reactant(1.5)
        f2 = Efus.Reactant(2.5)
        float_radical = @radical f1' + f2'
        @test float_radical isa Efus.Reactor{Float64}
        @test Efus.getvalue(float_radical) == 4.0
    end

    @testset "@reactor with setter" begin
        a = Efus.Reactant(5)
        # This reactor's setter will write back to `a`
        writable_reactor = @reactor a' * 2 (v -> Efus.setvalue!(a, round(v / 2)))

        @test Efus.getvalue(writable_reactor) == 10

        Efus.setvalue!(writable_reactor, 30)

        # The reactor's value itself is lazy, so it's fouled
        @test Efus.isfouled(writable_reactor)
        # But the setter should have fired, updating `a`
        @test Efus.getvalue(a) == 15
        # Now, getting the reactor's value will update it based on the new `a`
        @test Efus.getvalue(writable_reactor) == 30
    end
end

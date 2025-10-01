using IonicEfus
using Test

@testset "IonicEfus.jl" begin

    @testset "Parser and Codegen" begin
        @testset "Component Calls" begin
            @testset "Basic component call" begin
                @test IonicEfus.codegen_string("MyComponent") isa String
            end

            @testset "Component with complex arguments" begin
                @test IonicEfus.codegen_string("MyComponent text=\"Hello\" number=123 flag=true") isa String
            end

            @testset "Component with splat arguments" begin
                @test IonicEfus.codegen_string("MyComponent args...") isa String
            end

            @testset "Deeply nested components" begin
                @test IonicEfus.codegen_string("""
                Panel
                  Column
                    Row
                      Button text="Click Me"
                """) isa String
            end
        end

        @testset "Control Flow" begin
            @testset "Nested if-else in for loop" begin
                @test IonicEfus.codegen_string("""
                for item in items'
                  if item.type == :A
                    ComponentA data=item
                  else
                    ComponentB data=item
                  end
                end
                """) isa String
            end

            @testset "For-else loop" begin
                @test IonicEfus.codegen_string("""
                for i in []
                  Label text=(i)
                else
                  Label text="Empty"
                end
                """) isa String
            end

            @testset "Complex Nesting and Syntax Variations" begin
                @testset "For loop with '=' iterator" begin
                    @test IonicEfus.codegen_string("""
                    for i = 1:10
                      Label text=(i)
                    end
                    """) isa String
                end

                @testset "For loop with '∈' iterator" begin
                    @test IonicEfus.codegen_string("""
                    for i ∈ 1:10
                      Label text=(i)
                    end
                    """) isa String
                end

                @testset "Triple nested for loops with nested if" begin
                    @test IonicEfus.codegen_string("""
                    Container
                      for i in 1:2
                        for j = 1:2
                          for k ∈ 1:2
                            if i + j + k > 3
                              Label text="Sum is large"
                            else
                              Label text="Sum is small"
                            end
                          end
                        end
                      end
                    """) isa String
                end

                @testset "Mixed if/for nesting" begin
                    @test IonicEfus.codegen_string("""
                    if condition1'
                      Container
                        for item in list'
                          if item.is_special
                            SpecialComponent data=item
                          end
                        end
                    else
                      Label text="Nothing to show"
                    end
                    """) isa String
                end
            end
        end

        @testset "Data Types and Reactivity" begin
            @testset "Complex vector with reactive elements" begin
                @test IonicEfus.codegen_string("Comp value=[1, (a' + b'), :symbol, [c', d']]") isa String
            end

            @testset "Reactive assignment and usage" begin
                @test IonicEfus.codegen_string("Comp value=(my_var' = 5; my_var' * 2)") isa String
            end
        end

        @testset "Blocks and Snippets" begin
            @testset "Component with complex begin block" begin
                @test IonicEfus.codegen_string("""
                MyComponent value=begin
                  x = calculate_something(a', b')
                  if x > 10
                    :big
                  else
                    :small
                  end
                end
                """) isa String
            end

            @testset "Snippet with multiple parameters" begin
                @test IonicEfus.codegen_string("""
                MyComponent
                  do item::String, index::Int
                    Label text=(index + \": \" + item)
                  end
                """) isa String
            end

            @testset "Julia Block Statements" begin
                @testset "Simple Julia block" begin
                    @test IonicEfus.codegen_string("""
                    MyComponent
                      (println("Hello from Julia"))
                    """) isa String
                end

                @testset "Variable assignment and use in component" begin
                    @test IonicEfus.codegen_string("""
                    MyComponent
                      (c = 5; Label(text=c))
                    """) isa String
                end

                @testset "Multi-line Julia block" begin
                    @test IonicEfus.codegen_string("""
                    MyComponent
                      (
                        x = 10;
                        y = 20;
                        z = x + y;
                        Label(text=z)
                      )
                    """) isa String
                end
            end
        end

        @testset "Original complex test case" begin
            @test IonicEfus.codegen_string("""
            Label padding=[
              (d' = c' * ama';d' / 4),
              do c::Int
                Button text=ama
              end,
              (ama', 4)
            ]
            """) isa String
        end
    end

    @testset "Invalid Syntax" begin
        @testset "Unterminated if" begin
            @test_throws IonicEfus.EfusError IonicEfus.codegen_string("""
            if a > b
              Label text="Missing end"
            """)
        end

        @testset "Unterminated for" begin
            @test_throws IonicEfus.EfusError IonicEfus.codegen_string("""
            for i in 1:10
              Label text=(i)
            """)
        end

        @testset "Unterminated do block" begin
            @test_throws IonicEfus.EfusError IonicEfus.codegen_string("""
            MyComponent
              do
                Label
            """)
        end

        @testset "Invalid component argument" begin
            @test_throws IonicEfus.EfusError IonicEfus.codegen_string("MyComponent text=")
            @test_throws IonicEfus.EfusError IonicEfus.codegen_string("MyComponent =value")
        end

        @testset "Unmatched brackets in vector" begin
            @test_throws IonicEfus.EfusError IonicEfus.codegen_string("MyComponent value=[1, 2, (a + b]")
        end

        @testset "Unexpected 'else'" begin
            @test_throws IonicEfus.EfusError IonicEfus.codegen_string("""
            else
              Label text="misplaced else"
            end
            """)
        end

        @testset "Unescaped quotes in string" begin
            @test_throws IonicEfus.EfusError IonicEfus.codegen_string("Comp text=\"Hello, \"world\"!\"")
        end
    end

    @testset "Reactivity System (Unit Tests)" begin
        @testset "Reactant" begin
            r = IonicEfus.Reactant(10)
            @test IonicEfus.getvalue(r) == 10
            IonicEfus.setvalue!(r, 20)
            @test IonicEfus.getvalue(r) == 20
        end

        @testset "Catalyst and Reactions" begin
            r = IonicEfus.Reactant(5)
            c = IonicEfus.Catalyst()
            triggered_value = 0
            
            reaction_fn = (reactant) -> triggered_value = IonicEfus.getvalue(reactant)
            
            IonicEfus.catalyze!(c, r, reaction_fn)
            
            IonicEfus.setvalue!(r, 15)
            @test triggered_value == 15
            
            # Test inhibit!
            IonicEfus.inhibit!(c, r, reaction_fn)
            IonicEfus.setvalue!(r, 25)
            @test triggered_value == 15 # Should not have changed

            # Test denature!
            IonicEfus.catalyze!(c, r, reaction_fn)
            IonicEfus.setvalue!(r, 35)
            @test triggered_value == 35
            IonicEfus.denature!(c)
            IonicEfus.setvalue!(r, 45)
            @test triggered_value == 35 # Should not have changed
        end

        @testset "Reactor" begin
            a = IonicEfus.Reactant(10)
            b = IonicEfus.Reactant(20)
            
            # Create a reactor that sums a and b
            sum_reactor = IonicEfus.Reactor(Int, () -> IonicEfus.getvalue(a) + IonicEfus.getvalue(b), nothing, [a, b])
            
            @test IonicEfus.getvalue(sum_reactor) == 30
            
            IonicEfus.setvalue!(a, 15)
            @test IonicEfus.isfouled(sum_reactor) == true
            @test IonicEfus.getvalue(sum_reactor) == 35
            @test IonicEfus.isfouled(sum_reactor) == false
            
            IonicEfus.setvalue!(b, 25)
            @test IonicEfus.isfouled(sum_reactor) == true
            @test IonicEfus.getvalue(sum_reactor) == 40
            @test IonicEfus.isfouled(sum_reactor) == false
        end
    end

    @testset "Macros (@reactor and @radical)" begin
        @testset "@reactor (Lazy Evaluation)" begin
            a = IonicEfus.Reactant(10)
            b = IonicEfus.Reactant(20)
            
            # Assumes Ionic.translate is available and works
            # We are testing the macro expansion here
            lazy_reactor = @reactor a' + b'
            
            @test lazy_reactor isa IonicEfus.Reactor{Int}
            @test IonicEfus.getvalue(lazy_reactor) == 30
            @test !IonicEfus.isfouled(lazy_reactor)

            IonicEfus.setvalue!(a, 15)
            
            # Should be fouled, but value should not have updated yet
            @test IonicEfus.isfouled(lazy_reactor)
            @test lazy_reactor.value == 30 
            
            # Now, getvalue should trigger the update
            @test IonicEfus.getvalue(lazy_reactor) == 35
            @test !IonicEfus.isfouled(lazy_reactor)
        end

        @testset "@radical (Eager Evaluation)" begin
            a = IonicEfus.Reactant(10)
            b = IonicEfus.Reactant(20)
            
            eager_reactor = @radical a' + b'
            
            @test eager_reactor isa IonicEfus.Reactor{Int}
            @test IonicEfus.getvalue(eager_reactor) == 30
            @test !IonicEfus.isfouled(eager_reactor)

            IonicEfus.setvalue!(a, 15)
            
            # Should have re-computed immediately
            @test !IonicEfus.isfouled(eager_reactor)
            @test IonicEfus.getvalue(eager_reactor) == 35
        end

        @testset "Type Inference" begin
            s1 = IonicEfus.Reactant("Hello")
            s2 = IonicEfus.Reactant(", world!")
            str_reactor = @reactor s1' * s2'
            @test str_reactor isa IonicEfus.Reactor{String}
            @test IonicEfus.getvalue(str_reactor) == "Hello, world!"

            f1 = IonicEfus.Reactant(1.5)
            f2 = IonicEfus.Reactant(2.5)
            float_radical = @radical f1' + f2'
            @test float_radical isa IonicEfus.Reactor{Float64}
            @test IonicEfus.getvalue(float_radical) == 4.0
        end

        @testset "@reactor with setter" begin
            a = IonicEfus.Reactant(5)
            # This reactor's setter will write back to `a`
            writable_reactor = @reactor a' * 2 (v -> IonicEfus.setvalue!(a, v / 2))

            @test IonicEfus.getvalue(writable_reactor) == 10
            
            IonicEfus.setvalue!(writable_reactor, 30)
            
            # The reactor's value itself is lazy, so it's fouled
            @test IonicEfus.isfouled(writable_reactor)
            # But the setter should have fired, updating `a`
            @test IonicEfus.getvalue(a) == 15
            # Now, getting the reactor's value will update it based on the new `a`
            @test IonicEfus.getvalue(writable_reactor) == 30
        end
    end
end

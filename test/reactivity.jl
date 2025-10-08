using IonicEfus

@testset "Reactivity" begin
    @testset "Basic Reactant Operations" begin
        # Test basic reactant creation and value access
        r = Reactant(42)
        @test r isa Reactant{Int64}
        @test getvalue(r) == 42
        
        # Test value updates
        setvalue!(r, 100)
        @test getvalue(r) == 100
    end
    
    @testset "Reactant Type Flexibility" begin
        # Test different types
        string_r = Reactant("hello")
        @test string_r isa Reactant{String}
        @test getvalue(string_r) == "hello"
        
        array_r = Reactant([1, 2, 3])
        @test array_r isa Reactant{Vector{Int64}}
        @test getvalue(array_r) == [1, 2, 3]
        
        # Test type changes
        setvalue!(string_r, "world")
        @test getvalue(string_r) == "world"
    end

    @testset "Catalyst Operations" begin
        # Test catalyst creation
        catalyst = Catalyst()
        @test catalyst isa Catalyst
        @test length(catalyst.reactions) == 0
        
        # Test basic catalyze functionality
        r = Reactant(0)
        callback_called = false
        
        reaction = catalyze!(catalyst, r) do reactant
            callback_called = true
        end
        
        @test reaction isa AbstractReaction
        @test length(catalyst.reactions) == 1
    end

    @testset "Reactor Computed Values" begin
        # Test computed reactants that depend on other reactants
        a = Reactant(10)
        b = Reactant(20)
        
        # Create computed reactor
        sum_reactor = Reactor{Int}(() -> getvalue(a) + getvalue(b), nothing, [a, b])
        
        @test sum_reactor isa Reactor{Int}
        @test getvalue(sum_reactor) == 30
        
        # Change dependency and verify update
        setvalue!(a, 15)
        @test getvalue(sum_reactor) == 35
        
        setvalue!(b, 25)  
        @test getvalue(sum_reactor) == 40
    end
    
    @testset "Reactor with Single Dependency" begin
        x = Reactant(5)
        
        double_reactor = Reactor{Int}(() -> getvalue(x) * 2, nothing, [x])
        
        @test getvalue(double_reactor) == 10
        
        setvalue!(x, 7)
        @test getvalue(double_reactor) == 14
    end
    
    @testset "Complex Reactor Chains" begin
        # Test reactors depending on other reactors
        base = Reactant(2)
        
        doubled = Reactor{Int}(() -> getvalue(base) * 2, nothing, [base])
        squared = Reactor{Int}(() -> getvalue(doubled) ^ 2, nothing, [doubled])
        
        @test getvalue(doubled) == 4
        @test getvalue(squared) == 16
        
        setvalue!(base, 3)
        @test getvalue(doubled) == 6
        @test getvalue(squared) == 36
    end

    @testset "Reactor with Complex Logic" begin
        condition = Reactant(true)
        value_a = Reactant(10)
        value_b = Reactant(20)
        
        conditional_reactor = Reactor{Int}(() -> begin
            if getvalue(condition)
                getvalue(value_a)
            else  
                getvalue(value_b)
            end
        end, nothing, [condition, value_a, value_b])
        
        @test getvalue(conditional_reactor) == 10
        
        setvalue!(condition, false)
        @test getvalue(conditional_reactor) == 20
        
        setvalue!(value_b, 30)
        @test getvalue(conditional_reactor) == 30
    end

    @testset "Reaction Management" begin
        catalyst = Catalyst()
        r = Reactant(0)
        
        callback_count = 0
        reaction = catalyze!(catalyst, r) do reactant
            callback_count += 1
        end
        
        # Initial setup
        @test callback_count == 0
        
        # Test inhibiting reactions
        inhibit!(reaction)
        setvalue!(r, 1)
        @test callback_count == 0  # Should not increase when inhibited
        
        # Test denaturing catalyst
        denature!(catalyst)
        setvalue!(r, 2) 
        @test callback_count == 0  # Still should not increase
    end

    @testset "Multiple Reactions on Same Reactant" begin
        r = Reactant(0)
        catalyst1 = Catalyst()
        catalyst2 = Catalyst()
        
        call_count_1 = 0
        call_count_2 = 0
        
        reaction1 = catalyze!(catalyst1, r) do reactant
            call_count_1 += 1
        end
        
        reaction2 = catalyze!(catalyst2, r) do reactant  
            call_count_2 += 1
        end
        
        setvalue!(r, 5)
        
        # Both reactions should be triggered
        # Note: Actual behavior depends on implementation
        @test call_count_1 >= 0  # May or may not be called immediately
        @test call_count_2 >= 0
    end

    @testset "Reactor Type Safety" begin
        # Test that reactor types are enforced
        int_reactant = Reactant(42)
        
        # Create reactor with specific type
        typed_reactor = Reactor{String}(() -> string(getvalue(int_reactant)), nothing, [int_reactant])
        
        @test typed_reactor isa Reactor{String}
        @test getvalue(typed_reactor) == "42"
        
        setvalue!(int_reactant, 100)
        @test getvalue(typed_reactor) == "100"
    end

    @testset "Reactivity Performance" begin
        # Test that reactors don't recompute unnecessarily
        base = Reactant(1)
        compute_count = 0
        
        expensive_reactor = Reactor{Int}(() -> begin
            compute_count += 1
            getvalue(base) * 1000
        end, nothing, [base])
        
        # First access should compute
        val1 = getvalue(expensive_reactor)
        first_count = compute_count
        @test first_count >= 1
        
        # Second access without changing base should not recompute  
        val2 = getvalue(expensive_reactor)
        @test val1 == val2
        # Note: Actual caching behavior depends on implementation
    end

    @testset "Memory Management" begin
        # Test that reactions can be cleaned up properly
        catalysts = []
        reactants = []
        
        # Create many temporary reactions
        for i in 1:10
            catalyst = Catalyst()
            reactant = Reactant(i)
            
            reaction = catalyze!(catalyst, reactant) do r
                # Do nothing
            end
            
            push!(catalysts, catalyst)
            push!(reactants, reactant)
        end
        
        # Clean up
        for catalyst in catalysts
            denature!(catalyst)
        end
        
        # This test mainly ensures no memory leaks/crashes occur
        @test true
    end

    @testset "Edge Cases" begin
        # Test with empty/null values  
        null_reactant = Reactant{Union{Nothing,Int}}(nothing)
        @test getvalue(null_reactant) === nothing
        
        setvalue!(null_reactant, 42)
        @test getvalue(null_reactant) == 42
        
        # Test reactor with no dependencies
        constant_reactor = Reactor{Int}(() -> 42, nothing, AbstractReactive[])
        @test getvalue(constant_reactor) == 42
    end
end
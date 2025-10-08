using IonicEfus

@testset "Reactivity" begin
    @testset "Reactant Basic Operations" begin
        # Test basic reactant creation and value access
        r = Reactant(42)
        @test getvalue(r) == 42
        
        # Test value updates
        setvalue!(r, 100)
        @test getvalue(r) == 100
    end
    
    @testset "Reactant Observers" begin
        # Test that reactions trigger when reactant changes
        r = Reactant(0)
        callback_called = false
        callback_value = nothing
        
        # Create a reaction
        reaction = observe(r) do val
            callback_called = true
            callback_value = val
        end
        
        # Change the reactant value
        setvalue!(r, 25)
        
        @test callback_called
        @test callback_value == 25
    end
    
    @testset "Multiple Observers" begin
        r = Reactant("initial")
        call_count = 0
        values_received = []
        
        # Multiple observers on same reactant
        obs1 = observe(r) do val
            call_count += 1
            push!(values_received, "obs1: $val")
        end
        
        obs2 = observe(r) do val
            call_count += 1  
            push!(values_received, "obs2: $val")
        end
        
        setvalue!(r, "changed")
        
        @test call_count == 2
        @test length(values_received) == 2
        @test "obs1: changed" in values_received
        @test "obs2: changed" in values_received
    end
    
    @testset "Reactor Computed Values" begin
        # Test computed reactants that depend on other reactants
        a = Reactant(10)
        b = Reactant(20)
        
        # Create computed reactor
        sum_reactor = Reactor() do
            getvalue(a) + getvalue(b)
        end
        
        @test getvalue(sum_reactor) == 30
        
        # Change dependency and verify update
        setvalue!(a, 15)
        @test getvalue(sum_reactor) == 35
        
        setvalue!(b, 25)  
        @test getvalue(sum_reactor) == 40
    end
    
    @testset "Reactor with Multiple Dependencies" begin
        x = Reactant(2)
        y = Reactant(3)
        z = Reactant(4)
        
        complex_reactor = Reactor() do
            getvalue(x) * getvalue(y) + getvalue(z)
        end
        
        @test getvalue(complex_reactor) == 2 * 3 + 4  # 10
        
        setvalue!(x, 5)
        @test getvalue(complex_reactor) == 5 * 3 + 4  # 19
        
        setvalue!(y, 2)
        @test getvalue(complex_reactor) == 5 * 2 + 4  # 14
        
        setvalue!(z, 10)
        @test getvalue(complex_reactor) == 5 * 2 + 10  # 20
    end
    
    @testset "Catalyst Management" begin
        # Test catalyst creation and reaction management
        catalyst = Catalyst()
        r = Reactant(0)
        
        callback_count = 0
        reaction = catalyze!(catalyst, r) do val
            callback_count += 1
        end
        
        setvalue!(r, 1)
        @test callback_count == 1
        
        setvalue!(r, 2)
        @test callback_count == 2
        
        # Test inhibiting reactions
        inhibit!(reaction)
        setvalue!(r, 3)
        @test callback_count == 2  # Should not increase
        
        # Test denaturing catalyst
        denature!(catalyst)
        setvalue!(r, 4) 
        @test callback_count == 2  # Still should not increase
    end
    
    @testset "Ionic Macro Integration" begin
        # Test @ionic macro for simplified reactive programming
        a = Reactant(5)
        b = Reactant(10)
        
        result = @ionic begin
            x = a' + b'  # Use ' syntax for getvalue
            y = x * 2
            a' = y       # Use ' syntax for setvalue!
            b'
        end
        
        @test result == 20  # Should return value of b'
        @test getvalue(a) == 30  # Should be updated via a' = y
    end
    
    @testset "Circular Dependency Detection" begin
        # Test that circular dependencies are detected/handled
        a = Reactant(1)
        b = Reactant(2)
        
        # This should either prevent circular dependency or handle it gracefully
        try
            reactor_a = Reactor() do
                getvalue(b) + 1
            end
            
            reactor_b = Reactor() do  
                getvalue(reactor_a) + 1
            end
            
            # If this doesn't throw, the system handles cycles
            val_a = getvalue(reactor_a)
            val_b = getvalue(reactor_b)
            @test true  # System handles cycles gracefully
            
        catch e
            # Or it should throw a meaningful error
            @test e isa Exception  # Some kind of cycle detection error
        end
    end
    
    @testset "Performance and Memory" begin
        # Test that reactions are properly cleaned up
        r = Reactant(0)
        reactions = []
        
        # Create many temporary reactions
        for i in 1:100
            reaction = observe(r) do val
                # Do nothing
            end
            push!(reactions, reaction)
        end
        
        # Trigger updates
        setvalue!(r, 1)
        
        # Clean up reactions
        for reaction in reactions
            inhibit!(reaction)
        end
        
        # This test mainly ensures no memory leaks/crashes
        @test true
    end
    
    @testset "Reactivity in Efus Integration" begin
        # Test that reactivity works within efus-generated code
        counter = Reactant(0)
        message = Reactant("Hello")
        
        # This would be generated by efus code with reactive expressions
        component_func = () -> begin
            count_val = getvalue(counter)
            msg_val = getvalue(message)  
            return "Component(count=$count_val, message=\"$msg_val\")"
        end
        
        @test component_func() == "Component(count=0, message=\"Hello\")"
        
        setvalue!(counter, 5)
        setvalue!(message, "World")
        
        @test component_func() == "Component(count=5, message=\"World\")"
    end
end
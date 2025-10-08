using IonicEfus

@testset "Integration Tests" begin
    @testset "End-to-End efus Macro" begin
        # Test complete pipeline: efus string -> tokenize -> parse -> generate -> execute

        # Mock some components for testing
        Label = (; text, size = 12) -> nothing
        Button = (; text, onclick = nothing) -> nothing
        Container = (; children...) -> nothing

        result = efus"""
        Container
          Label text="Welcome" size=16
          Button text="Click me"
        """

        @test result isa Vector  # Should return vector of components
        @test length(result) > 0
    end

    @testset "Reactive Integration" begin
        # Test reactivity works through the complete pipeline
        counter = Reactant(0)
        message = Reactant("Hello")

        # Mock component
        Display = (; count, msg) -> nothing

        component = efus"""
        Display count=counter' msg=message'
        """

        # Update reactants
        setvalue!(counter, 5)
        setvalue!(message, "Updated")

        # Re-evaluate (this depends on how your system handles reactivity)
        updated_component = efus"""
        Display count=counter' msg=message'
        """

        @test contains(string(updated_component), "5")
        @test contains(string(updated_component), "Updated")
    end

    @testset "Snippet Integration" begin
        # Test snippet definition and usage
        ListItem = (; text, active = false) -> active ? "★ $text" : "  $text"

        component = efus"""
        item_widget(text::String, selected::Bool = false)
          ListItem text=text active=selected
        end

        item_widget text="First Item" selected=true
        item_widget text="Second Item"
        """

        @test component isa Vector
        @test length(component) == 2  # Two item_widget calls
        @test contains(string(component[1]), "★")  # First is selected
        @test !contains(string(component[2]), "★")  # Second is not
    end

    @testset "Control Flow Integration" begin
        items = ["Apple", "Banana", "Cherry"]
        show_extras = true

        ListItem = (; text) -> "Item: $text"
        ExtraInfo = () -> "Extra information"

        result = efus"""
        for item in items
          ListItem text=item
        end

        if show_extras
          ExtraInfo
        end
        """

        @test result isa Vector
        @test length(result) >= 3  # At least 3 items + maybe extra info
        @test any(r -> contains(string(r), "Apple"), result)
        @test any(r -> contains(string(r), "Banana"), result)
        @test any(r -> contains(string(r), "Cherry"), result)

        if show_extras
            @test any(r -> contains(string(r), "Extra"), result)
        end
    end

    @testset "Julia Block Integration" begin
        # Test Julia code blocks execute correctly
        data = [1, 2, 3, 4, 5]

        Result = (; value) -> "Result: $value"

        component = efus"""
        (begin
          processed = map(x -> x * 2, data)
          sum_value = sum(processed)
        end)

        Result value=sum_value
        """

        @test component isa Vector
        # sum([2,4,6,8,10]) = 30
        @test any(r -> contains(string(r), "30"), component)
    end

    @testset "Type System Integration" begin
        # Test type assertions work correctly
        Component = (; text, count) -> "Component($text, $count)"

        text_value = "Hello"
        count_value = 42

        result = efus"""
        Component text=(text_value)::String count=(count_value)::Int
        """

        @test result isa Vector
        @test length(result) > 0
        @test contains(string(result[1]), "Hello")
        @test contains(string(result[1]), "42")
    end

    @testset "Error Reporting Integration" begin
        # Test that errors are properly reported with locations

        @test_throws ParseError @eval efus"""
        Component text="unterminated string
        """

        @test_throws ParseError @eval efus"""
        for item in items
          Component data=item
        # Missing end
        """

        # Test error messages contain location info
        try
            @eval efus"""
            BadSyntax invalid=
            """
            @test false  # Should have thrown
        catch e
            @test e isa Exception
            error_msg = string(e)
            @test contains(error_msg, "line") || contains(error_msg, "column")
        end
    end

    @testset "Performance Integration" begin
        # Basic performance test - should complete in reasonable time
        items = 1:100

        ListItem = (; index) -> "Item $index"

        start_time = time()

        result = efus"""
        for i in items
          ListItem index=i
        end
        """

        elapsed = time() - start_time

        @test elapsed < 5.0  # Should complete in under 5 seconds
        @test result isa Vector
        @test length(result) == 100
    end

    @testset "Memory Management Integration" begin
        # Test that large components don't leak memory excessively

        Component = (; id) -> "Component $id"

        # Create many components
        for batch in 1:10
            items = ((batch - 1) * 100 + 1):(batch * 100)

            result = efus"""
            for i in items
              Component id=i
            end
            """

            @test result isa Vector
            @test length(result) == 100
        end

        # If we get here without running out of memory, test passes
        @test true
    end

    @testset "Cross-Feature Integration" begin
        # Test combining multiple features together

        counter = Reactant(0)
        items = ["Task 1", "Task 2", "Task 3"]
        show_counter = true

        Counter = (; value) -> "Counter: $value"
        TaskItem = (; text, id) -> "Task $id: $text"
        Header = (; title) -> "=== $title ==="

        result = efus"""
        Header title="Todo List"

        if show_counter
          Counter value=counter'
        end

        task_item(text::String, index::Int)
          TaskItem text=text id=index
        end

        for (idx, task) in enumerate(items)
          task_item text=task index=idx
        end

        (begin
          # Update counter
          setvalue!(counter, length(items))
        end)
        """

        @test result isa Vector
        @test length(result) >= 4  # Header + Counter + 3 tasks

        # Verify all components are present
        result_str = join(string.(result), " ")
        @test contains(result_str, "Todo List")
        @test contains(result_str, "Counter: 3")  # Updated to length of items
        @test contains(result_str, "Task 1: Task 1")
        @test contains(result_str, "Task 2: Task 2")
        @test contains(result_str, "Task 3: Task 3")
    end
end


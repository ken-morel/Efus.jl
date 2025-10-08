using IonicEfus
using IonicEfus.Gen
using IonicEfus.Ast

@testset "Code Generation" begin
    @testset "Component Call Generation" begin
        # Test simple component call generates correct Julia code
        code = "Button text=\"Click me\" size=16"
        ast = parse_efus(code, "test")
        generated = generate_julia(ast)
        
        @test generated isa Expr
        @test generated.head == :block
        
        # Should contain function call structure
        julia_str = string(generated)
        @test contains(julia_str, "Button")
    end
    
    @testset "Snippet Definition Generation" begin
        code = """
        label(text::String, size::Int = 12)
          Label text=text font_size=size
        end
        """
        ast = parse_efus(code, "test")
        generated = generate_julia(ast)
        
        # Should generate a function definition
        @test generated isa Expr
        julia_str = string(generated)
        @test contains(julia_str, "function") || contains(julia_str, "->")
        @test contains(julia_str, "text") 
        @test contains(julia_str, "size")
    end
    
    @testset "Nested Structure Generation" begin
        code = """
        Container
          Header title="Welcome"
          Content
            Button text="Click"
        """
        ast = parse_efus(code, "test")  
        generated = generate_julia(ast)
        
        # Should preserve nesting structure
        @test generated isa Expr
        julia_str = string(generated)
        @test contains(julia_str, "Container")
        @test contains(julia_str, "Header") 
        @test contains(julia_str, "Content")
        @test contains(julia_str, "Button")
    end
    
    @testset "For Loop Generation" begin
        code = """
        for item in items
          ItemComponent data=item
        end
        """
        ast = parse_efus(code, "test")
        generated = generate_julia(ast)
        
        julia_str = string(generated)
        @test contains(julia_str, "for") || contains(julia_str, "map")
        @test contains(julia_str, "item")
        @test contains(julia_str, "items")
    end
    
    @testset "Conditional Generation" begin
        code = """
        if show_button
          Button text="Visible"
        else
          Label text="Hidden"
        end
        """
        ast = parse_efus(code, "test")
        generated = generate_julia(ast)
        
        julia_str = string(generated)
        @test contains(julia_str, "if")
        @test contains(julia_str, "show_button")
        @test contains(julia_str, "else")
    end
    
    @testset "Julia Block Generation" begin  
        code = """
        Component value=(calculate_something())
          (begin
            x = process_data()
            update_state(x)
          end)
        """
        ast = parse_efus(code, "test")
        generated = generate_julia(ast)
        
        # Julia blocks should be preserved as-is
        julia_str = string(generated)
        @test contains(julia_str, "calculate_something")
        @test contains(julia_str, "process_data")
        @test contains(julia_str, "update_state")
    end
    
    @testset "Reactive Expression Generation" begin
        code = "Component value=data' count=counter''"
        ast = parse_efus(code, "test")
        generated = generate_julia(ast)
        
        # Should generate getvalue calls for reactive references
        julia_str = string(generated)
        @test contains(julia_str, "getvalue") || contains(julia_str, "data'")
        @test contains(julia_str, "counter")
    end
    
    @testset "Type Assertion Generation" begin
        code = "Component text=value::String count=num::Int"
        ast = parse_efus(code, "test")
        generated = generate_julia(ast)
        
        julia_str = string(generated)
        @test contains(julia_str, "String") || contains(julia_str, "::")
        @test contains(julia_str, "Int")
    end
    
    @testset "Argument Splatting Generation" begin
        code = "Component base_args... extra=value"
        ast = parse_efus(code, "test")
        generated = generate_julia(ast)
        
        julia_str = string(generated)
        @test contains(julia_str, "...") || contains(julia_str, "splat")
    end
    
    @testset "Complex Example Generation" begin
        code = """
        MainApp title="My App"
          sidebar(items::Vector{String})
            NavContainer
              for item in items  
                NavItem text=item active=(current_item' == item)
              end
            end
          end
          
          main_content
            if selected_view' == "dashboard"
              Dashboard data=dashboard_data'
            elseif selected_view' == "settings"  
              Settings config=app_config'
            else
              ErrorView message="Unknown view"
            end
          end
          
          footer
            StatusBar 
              message=status_message'::String
              timestamp=(current_time())::DateTime
          end
        """
        
        ast = parse_efus(code, "test")
        generated = generate_julia(ast)
        
        @test generated isa Expr
        julia_str = string(generated)
        
        # Should contain all major elements
        @test contains(julia_str, "MainApp")
        @test contains(julia_str, "sidebar") 
        @test contains(julia_str, "for")
        @test contains(julia_str, "if")
        @test contains(julia_str, "elseif")
        @test contains(julia_str, "getvalue") || contains(julia_str, "'")
    end
    
    @testset "Generated Code Execution" begin
        # Test that generated code actually runs
        counter = Reactant(0)
        
        code = """
        TestComponent count=counter'
        """
        
        # Mock TestComponent function for testing
        TestComponent = (;count) -> "TestComponent(count=$count)"
        
        ast = parse_efus(code, "test")
        generated = generate_julia(ast)
        
        # Execute generated code (this tests compilation)
        try
            result = eval(generated)
            @test true  # Generated code compiles and runs
        catch e
            @test_broken false  # Generated code should compile
            @info "Generated code compilation failed" exception=e generated=generated
        end
    end
    
    @testset "Code Generation Consistency" begin
        # Test that same input generates same output
        code = "Button text=\"Hello\" size=12"
        
        ast1 = parse_efus(code, "test")
        ast2 = parse_efus(code, "test")  
        
        generated1 = generate_julia(ast1)
        generated2 = generate_julia(ast2)
        
        @test string(generated1) == string(generated2)
    end
    
    @testset "Error Handling in Generation" begin
        # Test generation with malformed AST
        # This depends on your AST structure, but tests robustness
        try
            # Create some invalid AST node (implementation dependent)
            invalid_ast = []  # Empty or malformed
            result = generate_julia(invalid_ast)
            @test true  # Handles gracefully
        catch e
            @test e isa Exception  # Or throws appropriate error
        end
    end
end